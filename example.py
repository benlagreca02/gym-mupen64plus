#!/bin/python
import gym, gym_mupen64plus
import time
import logging

print("Making env")
env = gym.make('Mario-Kart-Luigi-Raceway-v0')

print("Resetting env")
# for mario kart, this one call brings us all the way to 
# the start of the race
env.reset()

print("NOOP waiting for green light")
for i in range(18):
    (obs, rew, end, info) = env.step([128, 0, 0, 0, 0]) # NOOP until green light

print("GO! ...drive straight as fast as possible...")
for i in range(50):
    (obs, rew, end, info) = env.step([128, 0, 1, 0, 0]) # Drive straight

print("Doughnuts!!")
for i in range(10000):
    if i % 100 == 0:
        print("Step " + str(i))
    (obs, rew, end, info) = env.step([0, 0, 1, 0, 0]) # Hard-left doughnuts!
    (obs, rew, end, info) = env.step([0, 0, 0, 0, 0]) # Hard-left doughnuts!

input("Press <enter> to exit... ")
env.close()

