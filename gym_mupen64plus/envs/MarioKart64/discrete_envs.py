import abc
from gym_mupen64plus.envs.MarioKart64.mario_kart_env import MarioKartEnv
from gym import spaces

class DiscreteActions:
    # changing so 80 is center, i.e. range is 0-160
    ACTION_MAP = [
        ("NO_OP",         [128,   0, 0, 0, 0]),
        ("STRAIGHT",      [128,   0, 1, 0, 0]),
        ("BRAKE",         [128,   0, 0, 1, 0]),
        ("BACK_UP",       [128,   0, 0, 1, 0]),
        ("SOFT_LEFT",     [ 96,   0, 1, 0, 0]),
        ("LEFT",          [ 64,   0, 1, 0, 0]),
        ("HARD_LEFT",     [ 32,   0, 1, 0, 0]),
        ("EXTREME_LEFT",  [  0,   0, 1, 0, 0]),
        ("SOFT_RIGHT",    [160,   0, 1, 0, 0]),
        ("RIGHT",         [192,   0, 1, 0, 0]),
        ("HARD_RIGHT",    [224,   0, 1, 0, 0]),
        ("EXTREME_RIGHT", [255,   0, 1, 0, 0]),
    ]

    @staticmethod
    def get_action_space():
        return spaces.Discrete(len(DiscreteActions.ACTION_MAP))

    @staticmethod
    def get_controls_from_action(action):
        return DiscreteActions.ACTION_MAP[action][1]


class MarioKartDiscreteEnv(MarioKartEnv):

    ENABLE_CHECKPOINTS = True

    def __init__(self, character='mario', course='LuigiRaceway'):
        super(MarioKartDiscreteEnv, self).__init__(character=character, course=course)

        # This needs to happen after the parent class init to effectively override the action space
        self.action_space = DiscreteActions.get_action_space()

    def step(self, action):
        # Interpret the action choice and get the actual controller state for this step
        controls = DiscreteActions.get_controls_from_action(action)

        return super(MarioKartDiscreteEnv, self).step(controls)
