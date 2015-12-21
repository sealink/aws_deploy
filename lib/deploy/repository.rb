class Repository
  def repo
    @repo ||= Rugged::Repository.discover('.')
  end

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
    require 'open3'
    Open3.popen3("git rev-parse #{@tag}") { |i, o, e, t| e.read.chomp }.empty?
  end

  def sync!
    version!
    commit!
    tag!
    push!
  end

  def version!
    require 'fileutils'
    FileUtils.mkdir_p 'public'
    File.open('public/version.txt', 'w') { |file| file.puts(@tag) }
  end

  def commit!
    puts "Committing version.txt..."
    unless system('git add public/version.txt') && system("git commit -m #{commit_message}")
      fail "Failed to commit."
    end
  end

  def tag!
    puts "Tagging #{@tag} as new version..."
    unless system("git tag -a #{@tag} -m #{tag_message}")
      fail "Failed to tag"
    end
  end

  def push!
    # Have to invoke git binary here, as gem won't push.
    unless system('git push origin HEAD') && system('git push origin --tags')
      fail "Failed to git push."
    end
  end

  def tag_message
    "Deployed #{@tag}"
  end
  # Helper Git methods
  def index
    repo.index
  end

  def head
    repo.head
  end

  def now
    @now ||= Time.now
  end

  def commit_message
    @commit_message ||= "#{last_commit_message} - deploy"
  end

  def last_commit_message
    @last_commit_message ||= system('git log --pretty=%B -1')
  end

  def author
    @author ||= {
      name:  repo.config.get('user.name'),
      email: repo.config.get('user.email'),
      time:  now
    }
  end
end
