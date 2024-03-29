function [out, complete] = TrialCompleteness(tr, battery)

    % trial templates for different studies/batteris
    switch battery
        case 'PMS'
            exp = {...
                'scenes_trial',             5,      5       ;...
                'staticimages_trial',       8,      8       ;...
                'gap_trial',                48,     60      ;...
                'falsebelief_trial',        1,      1       ;...
                'biomotion_trial',          30,     30      ;...
                };
        case {'Schedule A', 'Schedule B'}
            exp = {...
                'reflex_trial',             12,     12      ;...
                'scenes_trial',             17,     17      ;...
                'staticimages_trial',       12,     12      ;...
                'gap_trial',                48,     60      ;...
                'falsebelief_trial',        1,      1       ;...
                'biomotion_trial',          30,     30      ;...
                };
        case 'Schedule C'
            exp = {...
                'scenes_trial',             5,      5       ;...
                'staticimages_trial',       8,      8       ;...
                'gap_trial',                48,     60      ;...
                'falsebelief_trial',        1,      1       ;...
                'biomotion_trial',          38,     38      ;...
                };            
        case 'Schedule D'
            exp = {...
                'scenes_trial',             5,      5       ;...
                'staticimages_trial',       8,      8       ;...
                'gap_trial',                48,     60      ;...
                'falsebelief_trial',        1,      1       ;...
                'biomotion_trial',          38,     38      ;...
                }; 
        otherwise
            exp = {...
                'scenes_trial',             5,      5       ;...
                'staticimages_trial',       8,      8       ;...
                'gap_trial',                48,     60      ;...
                'falsebelief_trial',        1,      1       ;...
                'biomotion_trial',          38,     38      ;...
                }; 
    end
            
            
    out = [tr, repmat({'N/A'}, size(tr, 1), 3)];
    complete = true;

    % loop through all expected task names
    for curE = 1:size(exp, 1)

        % look for exp task in presented tasks
        eName = exp{curE, 1};
        found = find(strcmpi(tr(:, 1), exp(curE, 1)), 1, 'first');

        if isempty(found)
            % exp trial not found in pres trials - add new row to output,
            % marking it as incomplete
            out = [out; {exp{curE, 1}, 0, 0, 0, 'INCOMPLETE'}];
            complete = false;
        else
            % exp trial was found - check number presented against exp min/max
            numPres = tr{found, 2};
            minExp = exp{curE, 2};
            maxExp = exp{curE, 3};
            out{found, 3} = minExp;
            out{found, 4} = maxExp;
            if numPres >= minExp && maxExp <= maxExp
                % correct number found
                out{found, 5} = 'COMPLETE';
            else
                out{found, 5} = 'INCOMPLETE';
                complete = false;
            end
        end

    end

end