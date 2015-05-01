class Example1Nonthreaded
  def initialize(log_dir)
    @log_dir = log_dir
    @url_counts = {}
  end

  def analyze_all_logs
    t1 = Time.now

    Dir.glob(File.join(@log_dir, '*.log')).each do |file|
      analyze_single_log(file)
    end

    top_urls = @url_counts.sort_by {|url, count| -count }[0,20]
    top_urls.each do |url, count|
      puts "#{count}\t#{url}"
    end

    puts "Took %0.1f seconds" % [Time.now - t1]
  end

  def analyze_single_log(file)
    puts "Analyzing #{file}"
    open(file).each_line do |line|
      if line.start_with?('Started ') && !line.include?('"/keepalive.html"')
        m = line.match(/"(.*)"/)
        if m
          url = m[0]
          @url_counts[url] = @url_counts[url] ? @url_counts[url] + 1 : 1
        end
      end
    end
  end
end

Example1Nonthreaded.new('logs/rsam-production').analyze_all_logs if __FILE__ == $0
