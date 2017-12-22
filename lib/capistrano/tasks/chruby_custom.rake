namespace :chruby do
  desc '[Chruby] release the current version inside the project'
  task :release do
    on roles(:all) do
      within current_path do
        execute :echo, "'#{fetch(:chruby_ruby)}' > chruby_version"
      end
    end
  end
end
