## Step Sequencer for Launchpad Mk II
## Author: Ben Simmonds

##| Specify Device Parameters for Launchpad Mk II
base = 36 ##set device basenote
noteRange = (range base, 100, 1)
n = 0
seq = (ring) ##| Construct Launchpad Matrix - 8 rows
8.times do
  seq = seq + noteRange.drop(4 * n).take(4) + noteRange.drop(32 + 4 * n).take(4)
  n += 1
end

define :init do ## Initialise
  set :a, (knit 0, 64) ## 0 = offLights
  set :seq, seq ## global Device Matrix
  procLights ## Reset the Board
end

define :metronome do
  sleep 1
  in_thread do
    loop do
      cue :clock
      sample :elec_tick
      sleep 1
    end
  end
end

define :chaser do
  sleep 4
end

##| Light Board Processor Function
define :procLights do
  a = get[:a]
  n = 0
  while n < a.count
    if a[n] == 1
      midi_note_on base +n, velocity: 15, channel: 1, port: "launchpad_emulator"
    else
      midi_note_off base +n, channel: 1, port: "launchpad_emulator"
    end
    n += 1
  end
end

##| Midi Listener function
define :stepListener do
  use_real_time
  noteOn, on= sync "/midi/launchpad_emulator/1/5/note_on"
  if on >0
    noteOn -= base
    old_a = get[:a]
    if old_a[noteOn] > 0 ##toggler
      new_a = old_a.put(noteOn, 0)
    else
      new_a = old_a.put(noteOn, 1)
    end
    set :a, new_a
    procLights
  end
end

## PROGRAM START ##
init
in_thread do
  loop do
    stepListener
  end
end
metronome

in_thread do
  sync :clock
  live_loop :chaser do
    seq = get[:seq]
    status = get[:a][seq.tick.round - base]
    puts  seq.look, status if seq.look == base
    midi seq.look, sustain: 0.125, velocity: 17, channel: 1, port: "launchpad_emulator"
    sleep 0.125
    if status == 1
      midi_note_on seq.look, velocity: 15, channel: 1, port: "launchpad_emulator"
    end
  end
end

in_thread do
  sync :clock
  live_loop :kick do
    seq = get[:seq]
    noteOn = get[:a][seq.tick.round - base]
    sample :drum_heavy_kick if noteOn == 1
    sleep 0.125
  end
end
