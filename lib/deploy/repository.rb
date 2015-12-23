require 'fileutils'
require 'open3'

class Repository
  def index_modified?
    ! system('git diff-index --cached --quiet HEAD --ignore-submodules --')
  end

  def prepare!(tag)
    fail "No tag given" unless tag
    @tag = tag
    sync! unless tag_exists?
  end

  private

  def tag_exists?
    Open3.popen3("git rev-parse #{@tag}") { |i, o, e, t| e.read.chomp }.empty?
  end

  def sync!
    version!
    commit!
    tag!
    push!
  end

  def version!
    FileUtils.mkdir_p 'public'
    File.open('public/version.txt', 'w') { |file| file.puts(@tag) }
  end

  def commit!
    puts "Committing version.txt..."
    unless system('git add public/version.txt') && system("git commit -m \"#{commit_message}\" ")
      fail "Failed to commit."
    end
  end

  def tag!
    puts "Tagging #{@tag} as new version..."
    unless system("git tag -a #{@tag} -m \"#{tag_message}\" ")
      fail "Failed to tag"
    end
  end

  def push!
    puts "Pushing changes to origin..."
    unless system('git push origin HEAD') && system('git push origin --tags')
      fail "Failed to git push."
    end
  end

  def tag_message
    "Deployed #{@tag}"
  end

  def commit_message
    @commit_message ||= "#{last_commit_message} - deploy"
  end

  def last_commit_message
    @last_commit_message ||= `git log --pretty=%B -1`.chomp('')
  end
end
