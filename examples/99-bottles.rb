#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "next"

class Singer < Next::Actor
  def self.props = Next.props(self)

  def receive(message)
    case message
    in :sing_final_verse
      puts <<~TEXT
        No more bottles of beer on the wall,
        no more bottles of beer.
        Go to the store and buy some more,
        99 bottles of beer on the wall...

      TEXT
    in [:sing_verse, bottles_left]
      puts <<~TEXT
        #{bottles_left} bottles of beer on the wall.
        #{bottles_left} bottles of beer.
        Take one down, pass it around,
        #{bottles_left - 1} bottles of beer on the wall.

      TEXT
    end

    sleep 0.1
    sender << :finished_singing
  end
end

class Conductor < Next::Actor
  def self.props(singer:) = Next.props(self, singer:)

  def initialize(singer:)
    @bottles_left = 99
    @singer = singer
  end

  def receive(message)
    case message
    when :start
      sing_next_verse
    when :finished_singing
      @bottles_left -= 1
      if @bottles_left == 0
        sing_final_verse
        context.system.terminate
      else
        sing_next_verse
      end
    end
  end

  private def sing_next_verse
    @singer.tell [:sing_verse, @bottles_left]
  end

  private def sing_final_verse
    @singer.tell :sing_final_verse
  end
end

system = Next.system("99-bottles")

singer = system.actor_of(Singer.props, "singer")
conductor = system.actor_of(Conductor.props(singer:), "conductor")

conductor.tell(:start)

system.await_termination
