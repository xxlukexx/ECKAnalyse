classdef ECKLog < handle
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties% (Access=private)
       
        FunName
        Headings
        Data
    
    end
    
    properties(Dependent)
        
        Table
        
    end
        
    methods
        
        % constructor
        function P=ECKLog      
        end
        
        function Sample(P, functionName, logHeadings, logData)
            
            % check data types
            if ~ischar(functionName)
                error('Function names must be passed as strings.')
            end
            
            if ~iscell(logHeadings) && ~iscell(logData)
                error('Both log headings and log data must be cell arrays.')
            end
            
            % check size of args
            if size(logHeadings,1)~=1
                error('Log headings must be a [1 x n] array.')
            end
            
            if size(logHeadings,2) ~= size(logData,2)
                error('The number of log headings must match the number of log data columns.')
            end
            
            % determine whether there's already an entry for this function
            % name
            entryFound=true;
            if isempty(P.FunName)
                entryFound=false;
            else
                % find the entry for the current function
                funEntry = find(strcmpi(functionName, P.FunName),1,'first');
                if isempty(funEntry), entryFound=false; end
            end               
                
            if entryFound
                % if an existing entry was found for this function...

                % check if same size headings/data
                if size(logHeadings,2) ~= size(P.Headings{funEntry},2)
                    error('Cannot append new log data to existing log data, as the number of columns do not match.')
                end

                % append data
                P.Data{funEntry} = [P.Data{funEntry}; logData];
                
            else                
               
                % create new entry
                P.FunName{end+1}        =       functionName;
                P.Headings{end+1}       =       logHeadings;
                P.Data{end+1}           =       logData;
 
            end
            
        end
        
        function tableOut = get.Table(P)
           
            % if no data, return empty
            if isempty(P.FunName)
                tableOut=[];
                return
            end
            
            % loop through all log entries, and concat headings and data
            for curLog = 1:size(P.FunName,2)
                tableOut{curLog} = [P.Headings{curLog}; P.Data{curLog}];
            end
            
        end
        
        function SaveTemp(P,path)
            
           % check that some log data exists
            if size(P.FunName,2)==0 
                return
            end
            
            path=P.CheckPath(path);
            tempData.Table = P.Table;
            tempData.Data = P.Data;
            tempData.Headings = P.Headings;
            tempData.FunName = P.FunName;
            
            save([path, '/tempData.mat'],'tempData','-v6');
            
        end
        
        function SaveLogs(P,logPath)
            
            % store log data into struct
            logData.Table = P.Table;
            logData.FunName = P.FunName;
            logPath=P.CheckPath(logPath);

            ECKSaveLog(logPath, logData);
           
%             fprintf('\n<strong>Saving experimental log files:</strong>\n\n');
%             % check that some log data exists
%             if size(P.FunName,2)==0 
%                 warning('No data has been logged. Save failed.')
%                 return
%             end
%                 
%             numLogs = size(P.FunName,2);
%             for curLog = 1:numLogs
%                 
%                 curName = P.FunName{1,curLog};
%                 curTable = P.Table{curLog};
%                 curFile = strcat(logPath, '/', curName, '.csv');
%                 csvwritecell(curFile, curTable);
%                 
%             end
            
        end
        
        function [pathOut] = CheckPath(P,path)
            
            pathOut=path;
            
            % check that the path exists
            if exist(path,'dir')~=7
                warning('Specified path %s does not exist...', path)
                
                % try to generate temp path
                dateName=strrep(strrep(datestr(now),':','.'),'-','_');
                path=[pwd, '/TEMP_', dateName];  
                
                % does this temp path exist?
                if ~exist('path','dir')
                    warning(['Temp path generated (%s), does not exist,',...
                        'attempting to create...'],path)
                    [success,~,~]=mkdir(path);
                    if ~success
                        warning(['Unable to create temp path (%s). Using',...
                            'default Matlab path (%s) as a last ditch attempt...'])
                        path=pwd;
                    end
                end
            end
            
        end
                        
    end
    
end

