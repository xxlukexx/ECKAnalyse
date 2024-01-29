function ECKTitle(msg)
    
    if size(msg, 2) > 60
    else
        msg = [' ', msg,  repmat(' ', [1, 59 - size(msg, 2)])];
    end
    
    fprintf('_____________________________________________________________\n');
    fprintf('|                                                            |\n');
    fprintf('|<strong>%s</strong>|\n', msg);
    fprintf('|____________________________________________________________|\n\n');

end