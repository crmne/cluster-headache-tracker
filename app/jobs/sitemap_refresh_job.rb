class SitemapRefreshJob < ApplicationJob
  queue_as :default

  def perform
    SitemapGenerator::Interpreter.run
  end
end
