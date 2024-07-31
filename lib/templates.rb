# encoding: UTF-8

module Templates

  def self_new_tassk_from_templates_once_in_a_while(check_every_hours, *args)

    date = DateTime.now

    @last_checked ||= date

    diff = date - @last_checked
    puts "evaluate template diff #{diff.to_s}"
    return if @last_checked and (diff) * 24 > check_every_hours
    @last_checked = date

    self.new_tasks_from_templates(*args)
  end

  def self.new_tasks_from_templates(tasks, template_yaml_files, instantiated_file)

    date = DateTime.now
    date_s = date.to_s
    instantiated_tasks = (File.exist? instantiated_file) ?  File.open(instantiated_file, 'rb') { |file| YAML::load(file) } : {}

    any_added = false

    template_yaml_files.each do |template_yaml_file|
      next unless File.exist? template_yaml_file
      templates = File.open(template_yaml_file, 'rb') { |file| YAML::load(file) }
      templates.each do |template|
        suffix = case template[:instantiate]
        when :once_a_day
          date.strftime("%Y_%m_%d")
        when :once_a_month
          date.strftime("%Y_%m")
        when :once_a_week
          date.strftime("%Y_%U")
        when :once_a_quarter
          date.strftime("%Y_")+((Integer(date.strftime("%m").gsub(/^0*/, ''))-1) /3).to_s
        when :once_a_year
          date.strftime("%Y")
        end

        instance_name = "#{template[:name]}_#{suffix}"
        if not instantiated_tasks.include? instance_name
          h = tasks.hash_by_name(instance_name, :insert)
          template.each_pair {|k,v|
            h[k] = v unless k == :name
          }
          instantiated_tasks[instance_name] = date_s
          any_added = true
        end
      end
    end

    if any_added
      File.open(instantiated_file, 'wb') { |file| file.write(instantiated_tasks.to_yaml) }
      tasks.save()
    end
  end

end
