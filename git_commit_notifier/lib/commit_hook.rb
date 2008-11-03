require 'rubygems'
require 'cgi'
require 'net/smtp'
require 'sha1'
require File.dirname(__FILE__) + '/diff_to_html'
require File.dirname(__FILE__) + '/emailer'
require File.dirname(__FILE__) + '/git'

class CommitHook

  def self.run(rev1, rev2, ref_name)

    config = YAML.load_file('/usr/local/share/git_commit_notifier/config/config.yml')
    project_path = Dir.getwd

    project_config = config['projects'][project_path]

    recipient = project_config['recipient_address']
    recipient = Git.mailing_list_address if recipient.empty?

    repo = project_config['application_name']
    repo = Git.prefix if repo.empty?
    repo = 'scm' if repo.empty?
    prefix = "[#{repo}][#{short_ref_name(ref_name)}]"

    diff2html = DiffToHtml.new
    diff2html.diff_between_revisions rev1, rev2, repo, ref_name
    unless recipient.empty?
      diff2html.result.reverse.each_with_index do |result, i|
        nr = diff2html.result.size > 1 ? "[#{sprintf('%03d', i)}]": ''
        emailer = Emailer.new config, project_path, recipient, result[:author_email], result[:author_name],
                       "#{prefix}#{nr} #{result[:message]}", result[:text_content], result[:html_content], rev1, rev2, ref_name
        emailer.send
      end
    end
  end

  def self.short_ref_name(ref_name)
    ref_name.strip.match(/refs\/(.*)\/(.*)/)[0]
    ref_type = $1
    ref = $2
    ref_type =~ /^head/ ? ref : ref_name
  end

end