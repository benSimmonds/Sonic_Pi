## 64-Step Sequencer for Launchpad Mk II
## Author: Ben Simmonds

##| Specify Device Parameters --
base = 36 ##set device basenote
noPads = 64
noteRange = (range base, base +noPads, 1)

##| Construct Matrix
seq = (ring)
n = 0
8.times do seq = seq + noteRange.drop(4 * n).take(4) + noteRange.drop(32 + 4 * n).take(4)
  n += 1
end
##| End Device Paramaters --

define :startUp do
  set :seq, seq ## global Device Matrix
  set :bpm, 80
  set :voices, 8 #max number of patterns
end

define :init do ## Initialise all Loops
  set :lpVc1, (knit 0, noPads)
  set :lpVc2, (knit 0, noPads)
  set :lpVc3, (knit 0, noPads)
  set :lpVc4, (knit 0, noPads)
  set :lpVc5, (knit 0, noPads)
  set :lpVc6, (knit 0, noPads)
  set :lpVc7, (knit 0, noPads)
  set :lpVc8, (knit 0, noPads)
  set :currLoopID, "lpVc1" ##default to first voice's loop
  set :activeLoop, (knit 0, noPads)
  procLights ## Reset the Board
end

##| Light Board Processor Function
define :procLights do
  a = get[:activeLoop]
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

##| Midi Listeners
define :stepListener do
  use_real_time
  noteOn, on= sync "/midi/launchpad_emulator/1/5/note_on"
  set :noteOn, noteOn
end

define :loopSelect do
  a = get[:activeLoop]
  p = get[:currLoopID] #previous loopID
  set ":#{p}", a #save active to previous loop, should already be done, but... safety first?
  set :currLoopID, "lpVc#{get[:noteOn] - 99}" #select new current loop ID
  #get new current loop to assign to active
  c = get[:"#{get[:currLoopID]}"]
  set :activeLoop, c #apply selected loop to active
  puts get[:activeLoop]
  procLights
end

define :patternEditor do
  step = get[:noteOn] - base
  a = get[:activeLoop]
  c = get[:currLoopID]
  if a[step] == 0
    a = a.put(step, 1)
  else a = a.put(step, 0)
  end
  set :"#{c}", a
  set :activeLoop, a
  procLights
end

define :chaser do with_bpm get[:bpm] do
    seq = get[:seq]
    status = get[:activeLoop][seq.look.round - base]
    midi_note_on seq.look, velocity: 17, channel: 1, port: "launchpad_emulator"
    sleep 0.250
    midi_note_on seq.look, velocity: 15, channel: 1, port: "launchpad_emulator" if status == 1
    midi_note_off seq.look if status == 0
  end
end


## PROGRAM START ##
startUp
init

in_thread do
  loop do
    stepListener
    if get[:noteOn] >=100
      loopSelect
    else if get[:noteOn] >=36
      patternEditor
    end
  end
end
end

sleep 1

live_loop :metronome do with_bpm get[:bpm] do
    cue :metronome
    sleep 4
  end
end

live_loop :metronome16 do with_bpm get[:bpm] do
    n =0
    while n <65
      sync :metronome
      n += 1
    end
    cue :metronome16
  end
end

in_thread do
  sync :metronome
  live_loop :chaser do
    chaser
    tick
  end
end

in_thread do
  sync :metronome
  live_loop :kick do with_bpm get[:bpm] do
      seq = get[:seq]
      hit = get[:lpVc1][seq.tick.round - base]
      sample :drum_bass_soft, lpf: 45, amp: 1.5 if hit == 1
      sample :drum_heavy_kick, lpf: 50, amp: 0.8 if hit == 1
      sleep 0.250
    end
  end
end

in_thread do
  sync :metronome
  live_loop :snare do with_bpm get[:bpm] do
      seq = get[:seq]
      hit = get[:lpVc2][seq.tick.round - base]
      sample :drum_snare_soft, amp: 1 if hit == 1
      sleep 0.250
    end
  end
end

in_thread do
  sync :metronome
  live_loop :hats do with_bpm get[:bpm] do
      seq = get[:seq]
      hit = get[:lpVc3][seq.tick.round - base]
      sample :drum_cymbal_closed, amp: 1 if hit == 1
      sleep 0.250
      ##| stop
    end
  end
end

in_thread do
  sync :metronome
  live_loop :cow do with_bpm get[:bpm] do
      seq = get[:seq]
      hit = get[:lpVc4][seq.tick.round - base]
      sample :drum_cowbell, amp: 0.3, pitch: -5 if hit == 1
      sleep 0.250
    end
  end
end

##| For saving patterns
##| loop do
##|   puts get[:lpVc1]
##|   puts get[:lpVc2]
##|   puts get[:lpVc3]
##|   puts get[:lpVc4]
##|   sleep 16
##| end

##| Frozen Pattern for Later
##| kick = (ring 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0)
##| snare = (ring 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0)
##| hats = (ring 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1)
##| cowbell = (ring 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
