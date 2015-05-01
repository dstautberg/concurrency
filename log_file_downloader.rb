#! /usr/bin/env ruby

Bundler.require
require 'net/ssh'

Dotenv.load

class LogFileDownloader
  def initialize(env, argv)
    @username = env['LOG_FILE_DOWNLOADER_USERNAME']
    @password = env['LOG_FILE_DOWNLOADER_PASSWORD']
    @app = argv[0] || "rsam"
    @env = argv[1] || "dev"
    @local_log_dir = "logs/#{@app}-#{@env}"
    @remote_log_path = "/logs/#{@app}/#{@env}.log"
    @files_created = []
    @server_list = {
      'production' => %w{
        prod1 prod2 prod3 prod4 prod5 prod6 prod7 prod8
        prod9 prod10 prod11 prod12 prod13 prod14 prod15 prod16
      },
      'uat' => %w{ uat1 uat2 uat3 uat4 },
      'stage' => %w{ stage1 stage2 },
      'dev' => %w{ dev1 dev2 }
    }
  end

  def run
    FileUtils.mkdir_p(@local_log_dir)
    @threads = []
    @server_list[@env].each do |server|
      download_logs(server)
    end
    @threads.each { |t| t.join }
  end

  def download_logs(host)
    @threads << Thread.new do
      Net::SSH.start(host, @username, :password => @password) do |ssh|
        timestamp = Time.now.strftime("%Y-%m-%d_%H:%M:%S")
        open("#{@local_log_dir}/#{timestamp}-#{host}.log","w") do |f|
          f.write(ssh.exec!("cat #{@remote_log_path}"))
          @files_created << f.path
          puts "Wrote #{f.path}"
        end
      end
    end
  end

  def files_created
    @files_created
  end
end

LogFileDownloader.new(ENV, ARGV).run if __FILE__ == $0
