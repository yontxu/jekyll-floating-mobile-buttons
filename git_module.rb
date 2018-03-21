module GitModule
  #
  # Get all the files that have been changed between
  # HEAD (The most recent commit in the index) and
  # the commit_sha argument (This can be a normal SHA or HEAD^, HEAD~2, etc)
  # commit_sha the commit_sha to diff with HEAD (This can be a normal SHA or HEAD^, HEAD~2, etc)
  #
  def git_files_changed( commit_sha )
    files = `git diff --name-only HEAD #{commit_sha}`
    files = files.split(' ')
    files
  end

  #
  # List all the files that have been changed between
  # HEAD (The most recent commit in the index) and
  # the commit_sha argument (This can be a normal SHA or HEAD^, HEAD~2, etc)
  # commit_sha the commit_sha to diff with HEAD (This can be a normal SHA or HEAD^, HEAD~2, etc)
  #
  def list_git_files_changed( commit_sha )
    puts git_files_changed( commit_sha )
  end
end