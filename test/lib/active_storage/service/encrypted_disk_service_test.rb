require "test_helper"

class ActiveStorage::Service::EncryptedDiskServiceTest < ActiveSupport::TestCase
  setup do
    @service = ActiveStorage::Blob.service
    @key = SecureRandom.base58(24)
    @data = file_fixture("photo.jpg").binread
  end

  teardown do
    @service.delete(@key)
  end

  test "is the configured service" do
    assert_instance_of ActiveStorage::Service::EncryptedDiskService, @service
  end

  test "stores only ciphertext on disk" do
    @service.upload(@key, StringIO.new(@data), checksum: OpenSSL::Digest::MD5.base64digest(@data))

    stored = File.binread(@service.path_for(@key))

    assert_not_equal @data, stored
    assert_not_includes stored, @data.byteslice(0, 64)
  end

  test "round-trips downloads, streams and chunks" do
    @service.upload(@key, StringIO.new(@data))

    assert_equal @data, @service.download(@key)
    assert_equal @data, [].tap { |chunks| @service.download(@key) { |chunk| chunks << chunk } }.join
    assert_equal @data.byteslice(10..20), @service.download_chunk(@key, 10..20)
  end

  test "round-trips empty files" do
    @service.upload(@key, StringIO.new(""))

    assert_equal "", @service.download(@key)
  end

  test "rejects uploads that don't match their checksum" do
    assert_raises ActiveStorage::IntegrityError do
      @service.upload(@key, StringIO.new(@data), checksum: OpenSSL::Digest::MD5.base64digest("something else"))
    end

    assert_not @service.exist?(@key)
  end

  test "refuses tampered files" do
    @service.upload(@key, StringIO.new(@data))

    path = @service.path_for(@key)
    contents = File.binread(path)
    contents.setbyte(-1, contents.getbyte(-1) ^ 1)
    File.binwrite(path, contents)

    assert_raises(OpenSSL::Cipher::CipherError) { @service.download(@key) }
  end

  test "raises when the file is missing" do
    assert_raises(ActiveStorage::FileNotFoundError) { @service.download(@key) }
  end
end
