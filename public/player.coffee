# Based on js-piano (https://github.com/michaelmp/js-piano) by:

# Copyright 2012 Michael Morris-Pearce

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
keys = [
  'A2', 'Bb2', 'B2', 'C3', 'Db3', 'D3', 'Eb3', 'E3', 'F3', 'Gb3', 'G3', 'Ab3',
  'A3', 'Bb3', 'B3', 'C4', 'Db4', 'D4', 'Eb4', 'E4', 'F4', 'Gb4', 'G4', 'Ab4',
  'A4', 'Bb4', 'B4', 'C5'
]

intervals = {}
depressed = {}

sound = (id) ->
  document.getElementById('sound-' + id)

fade = (key) ->
  audio = sound key
  stepfade = ->
    if audio
      if audio.volume > 0.2
        audio.volume = audio.volume * 0.95
      else
        audio.volume = audio.volume - 0.01
  ->
    clearInterval(intervals[key])
    intervals[key] = setInterval stepfade, 5

window.player = (key) ->
  audio = sound key
  clearTimeout depressed[key]

  if audio
    audio.pause()
    audio.volume = 1.0

    if audio.readyState >= 2
      audio.currentTime = 0
      audio.play()

    fade key
    pause = ->
      audio.pause()
      audio.currentTime = 0
    depressed[key] = setTimeout pause, 1000
