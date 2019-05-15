# frozen_string_literal: true

# Prompt for a value from the user
Puppet::Functions.create_function(:'io::prompt') do
  dispatch :prompt do
    required_param 'String', :banner
    optional_param 'Boolean', :sensitive
    return_type 'Variant[String, Sensitive[String]]'
  end

  def prompt(banner, sensitive = false)
    unless STDIN.tty? && STDOUT.tty?
      raise Bolt::Error.new("io::prompt() is only supported when using a TTY", "bolt/prompt")
    end

    STDOUT.print "#{banner}: "
    if sensitive
      value = STDIN.noecho(&:gets).chomp
      # With noecho, no newline is printed when the user presses enter, so do
      # it manually
      STDOUT.puts
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(value)
    else
      STDIN.gets.chomp
    end
  end
end
