require "active_storage/service/disk_service"

module ActiveStorage
  # A Disk service that encrypts every file with AES-256-GCM before it reaches the disk,
  # so the storage volume and its backups only ever hold ciphertext.
  #
  # The key is derived from the app's secret_key_base. Rotating secret_key_base without
  # re-encrypting makes stored files unreadable.
  #
  # Files are served only through the app's own authenticated controllers: the Active Storage
  # routes (and with them DiskController, which would stream raw ciphertext) are not drawn.
  class Service::EncryptedDiskService < Service::DiskService
    CIPHER = "aes-256-gcm"
    IV_LENGTH = 12
    AUTH_TAG_LENGTH = 16

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        data = io.read
        ensure_integrity_of_data(data, checksum) if checksum
        File.binwrite make_path_for(key), encrypt(data)
      end
    end

    def download(key)
      if block_given?
        instrument :streaming_download, key: key do
          yield decrypted_contents_of(key)
        end
      else
        instrument :download, key: key do
          decrypted_contents_of(key)
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        decrypted_contents_of(key).byteslice(range)
      end
    end

    def compose(source_keys, destination_key, **)
      File.binwrite make_path_for(destination_key), encrypt(source_keys.map { |key| decrypted_contents_of(key) }.join)
    end

    private
      def ensure_integrity_of_data(data, checksum)
        unless OpenSSL::Digest::MD5.base64digest(data) == checksum
          raise ActiveStorage::IntegrityError
        end
      end

      def encrypt(data)
        cipher = OpenSSL::Cipher.new(CIPHER).encrypt
        cipher.key = encryption_key
        iv = cipher.random_iv

        ciphertext = data.empty? ? cipher.final : cipher.update(data) + cipher.final
        iv + cipher.auth_tag(AUTH_TAG_LENGTH) + ciphertext
      end

      def decrypted_contents_of(key)
        decrypt File.binread(path_for(key))
      rescue Errno::ENOENT
        raise ActiveStorage::FileNotFoundError
      end

      def decrypt(contents)
        cipher = OpenSSL::Cipher.new(CIPHER).decrypt
        cipher.key = encryption_key
        cipher.iv = contents.byteslice(0, IV_LENGTH)
        cipher.auth_tag = contents.byteslice(IV_LENGTH, AUTH_TAG_LENGTH)
        cipher.auth_data = ""

        ciphertext = contents.byteslice((IV_LENGTH + AUTH_TAG_LENGTH)..)
        ciphertext.empty? ? cipher.final : cipher.update(ciphertext) + cipher.final
      end

      def encryption_key
        @encryption_key ||= Rails.application.key_generator.generate_key("active_storage/encrypted_disk_service", 32)
      end
  end
end
