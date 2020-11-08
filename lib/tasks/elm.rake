# frozen_string_literal: true

require 'filewatcher'

namespace :elm do
  desc 'Build elm.js'
  task :build do
    Dir.chdir('frontend') do
      system('elm make src/Main.elm --debug --output ../public/dribble.js')
    end
  end

  desc 'Build elm.js and watch for changes'
  task :watch do
    Rake::Task['elm:build'].execute

    Filewatcher.new('frontend/**/*.elm').watch do |_filename|
      Rake::Task['elm:build'].execute
      unless $?.exitstatus.zero?
        FileUtils.rm_rf 'frontend/elm-stuff'
        Rake::Task['elm:build'].execute
      end
    end
  end
end
