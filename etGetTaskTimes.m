function taskTimes = etGetTaskTimes

    taskTimes = {...
                'falsebelief_trial',        'TrialOnsetRemote',             'TrialOffsetRemote';...
                'asahi_trial',              'BaselineOnsetTimeRemote',      'StimImageOffsetTimeRemote';...
                'reflex_trial',             'MovieOnsetETRemoteTime',       6;...
                'scenes_trial',             'MovieOnsetETRemoteTime',       21;...
                'staticimages_trial',       'StimImageOnsetTimeRemote',     'StimImageOffsetTimeRemote';...
                'contingency_trial',        'TrialOnsetRemote',             'MovieOffsetRemote';...
                'emotion_trial',            'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
                'frequency_trial',          'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
                'kanisza_trial',            'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
                'ns_contingency_trial',     'TrialOnsetTimeRemote',         'RewardOffsetRemote';...
                'wm_trial',                 'TrialOnsetRemote',             'CurtainChosenDownRemote';...
                'cog_control_trial',        'TrialOnsetRemote',             'MovieOffsetRemote';...
                'ms_trial',                 'TrialOffsetTime',              'TrialOffsetRemote';...
                'soc_contingency_trial',    'TrialOffsetTime',              'TrialOffsetRemote';...
                'gap_trial',                'TrialOnsetRemoteTime',         'TrialOffsetRemoteTime';...
                'antisaccade_trial',        'TrialOnsetRemote',             'RewardOffsetRemote';...
                'antisaccadeinter_trial',   'TrialOnsetRemote',             'RewardOffsetRemote';...
                'biomotion_trial',          'OnsetTimeRemote',              'OffsetTimeRemote';...
                'bunnies_trial',            'TrialOnsetRemote',             'TrialOffsetRemote';...
                'changedet_trial',          'RemoteOnsetTime',              'RemoteOffsetTime';...
                'distract_trial',           'TrialOnsetRemote',             'TrialOffsetRemote';...
                'emomatch_trial',           'RemoteOnsetTime',              'RemoteOffsetTime';...
                'hab_trial',                'TrialOnsetRemote',             'TrialOffsetRemote';...
                'predictability_trial',     'TrialOffsetTime',              'TrialOffsetRemote';...
%                 'vissearch_trial',          'TrialOnsetRemote',             'TrialOffsetRemote';...
                'vpc_trial',                'TrialOnsetRemote',             'TrialOffsetRemote'};

end