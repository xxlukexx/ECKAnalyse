classdef ECKCodeGenerator < handle
    
    properties (Dependent, SetAccess = private)
        FunName
        FileOpen
        Filename
    end
    
    properties (Access = private)
        pOutputPath
        pFid
        pFileOpen = false;
        pFilename
        pFunName 
        pCodeCache
    end
    
    methods
        
        function obj = ECKCodeGenerator(path_output)
            % check path
            tryToMakePath(path_output)
            obj.pOutputPath = path_output; 
        end
        
        function delete(obj)
            if obj.pFileOpen
                fclose(obj.pFid);
            end
        end
        
        function [suc, oc] = StartFile(obj, taskName, suffix)
            suc = false;
            oc = 'Unknown error';
            % check name
            if ischar(taskName)
                vals = double(taskName);
                if ~all(    (vals >= 65 & vals <= 90)   |...
                            (vals >= 97 & vals <= 122)  |...
                            (vals >= 48 & vals <= 57)       );
                    oc = 'Illegal character -  taskName can only contain letters or numbers';
                    return
                end
            else
                oc = 'taskName must be char';
                return
            end
            % check suffix
            if ischar(suffix)
                vals = double(suffix);
                if ~all(    (vals >= 65 & vals <= 90)   |...
                            (vals >= 97 & vals <= 122)  |...
                            (vals >= 48 & vals <= 57)       );
                    oc = 'Illegal character -  suffix can only contain letters or numbers';
                    return
                end
            else
                oc = 'suffix must be char';
                return
            end
            % build filename & function name
            obj.pFunName = [taskName, '_', suffix];
            obj.pFilename = fullfile(obj.pOutputPath,...
                [obj.pFunName, '.m']);
            % open file
            obj.pFid = fopen(obj.pFilename, 'w');
            if obj.pFid == -1
                oc = 'Could not open file';
                return
            else
                obj.pFileOpen = true;
            end
            % write header
            obj.WriteFileDescription
            suc = true;
            oc = '';
        end
        
        function [suc, oc] = Write(obj, out)
            suc = false;
            oc = 'Unknown error';
            if ~obj.pFileOpen
                oc = 'File not open';
                return
            end
            if ~iscell(out), out = {out}; end
            cellfun(@(x) fprintf(obj.pFid, '%s\n', x), out,...
                'uniform', false);
            suc = true; 
            oc = '';
        end
        
        function [suc, oc, filename] = CloseFile(obj)
            suc = false;
            oc = 'Unknown error';
            if ~obj.pFileOpen
                oc = 'File not open';
                return
            end
            res = fclose(obj.pFid);
            if res == -1
                oc = 'Could not close file.';
                return
            else
                obj.pFileOpen = false;
            end
            filename = obj.pFilename;
            suc = true;
            oc = '';
        end
        
        function [suc, oc] = EditFile(obj)
            suc = false;
            oc = 'Unknown error';
            if ~obj.pFileOpen
                oc = 'File not open';
                return
            end
            edit(obj.pFilename)
        end
        
        function [suc, oc] = WriteCode(obj, id, varargin)
            
            suc = false;
            oc = 'Unknown error';
            if ~obj.pFileOpen
                oc = 'File not open';
                return
            end
            
            % check code cache
            if isempty(obj.pCodeCache) || isempty(fieldnames(obj.pCodeCache))
                error('No code has been cached. Use the CacheCode method first.')
            end
            
            % parse input arguments
            parser = inputParser;
            addParameter(   parser,     'backcolor',      '[0, 0, 0]'                   )
            addParameter(   parser,     'screennumber',   'max(Screen(''Screens''))'    )
            addParameter(   parser,     'filename',       ''                            )
            addParameter(   parser,     'foldername',     ''                            )
            addParameter(   parser,     'etname',         '<UNSET>'                     )
            addParameter(   parser,     'etrate',         '120'                         )
            addParameter(   parser,     'outputpath',     obj.pOutputPath               )
            addParameter(   parser,     'imagename',      'image'                       )
            addParameter(   parser,     'moviename',      'movie'                       )
            addParameter(   parser,     'soundname',      'sound'                       )
            parse(parser, varargin{:});
            
            % look for code segment that matches supplied ID
            found = find(strcmpi({obj.pCodeCache.FunName}, id), 1, 'first');
            if isempty(found)
                error('Could not find code segment with ID (%s)', id)
            end
            code = obj.pCodeCache(found).Code;
            
            % define tokens to replace
            rep = {...
                '#FUNNAME#',        obj.pFunName                        ;...
                '#BACKCOLOR#',      parser.Results.backcolor            ;...
                '#SCREENNUMBER#',   parser.Results.screennumber         ;...
                '#FILENAME#',       parser.Results.filename             ;...
                '#PATHNAME#',       parser.Results.foldername           ;...
                '#ETNAME#',         parser.Results.etname               ;...
                '#ETRATE#',         parser.Results.etrate               ;...
                '#PATH_OUTPUT#',    parser.Results.outputpath           ;...
                '#IMAGENAME#',      parser.Results.imagename            ;...
                '#MOVIENAME#',      parser.Results.moviename            ;...
                '#SOUNDNAME#',      parser.Results.soundname            ;...
                };
            
            % replace tokens
            numRep = size(rep, 1);
            for r = 1:numRep
                code = strrep(code, rep{r, 1}, rep{r, 2});
            end
            
            % write code to file
            obj.Write(code)
            obj.Write('')
            
            suc = true;
            oc = '';
        end
        
        function WriteFileDescription(obj)
            out{1} = ['% ', repmat('/', 1, 73)];
            out{2} = sprintf('%%    %s', obj.pFunName);
            out{3} = sprintf('%%    %s', datestr(now));
            out{end + 1} = ['% ', repmat('/', 1, 73)];
            obj.Write(out)
        end
        
        function [suc, oc] = CacheCode(obj, codePath)
            suc = false;
            oc = 'Unknown error';
            if ~exist(codePath, 'dir')
                oc = 'codePath not found';
                return
            end                
            d = dir([codePath, filesep, '*.m']);
            obj.pCodeCache = struct;
            for f = 1:length(d)
                fn = strrep(d(f).name, 'cg_', '');
                fn = strrep(fn, '.m', '');
                obj.pCodeCache(f).FunName = fn;
                obj.pCodeCache(f).Code = fileread(fullfile(codePath,...
                    d(f).name));
            end
            suc = true;
            oc = '';
        end
        
        function val = get.FunName(obj)
            val = obj.pFunName;
        end
        
        function val = get.FileOpen(obj)
            val = obj.pFileOpen;
        end
        
        function val = get.Filename(obj)
            val = obj.pFilename;
        end
                
    end
    
end