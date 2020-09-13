# frozen_string_literal: true

$LOAD_PATH.unshift 'lib'

require 'rubygems'
require 'bundler'

Bundler.require

require './app'

run Dribble
