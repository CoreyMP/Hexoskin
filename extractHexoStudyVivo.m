clear all
close all
clc

%% SPECIFY EXCEL FILE AND SHEET NUMBER, THEN READ EXCEL FILE
renameFile = 'Rename the file once you have a VIVOSENSE mastersheet'
filename = 'PRP-Hexoskin-1Hz-Summary.xlsx'; % Rename this


dataDirName = 'HEXO_STUDY_VIVO_DATA_PARSED\';
mkdir(dataDirName);

subjectsHexoStudy;

for x = 1:length(subjects)
    tmp = subjects(x);
    tmp2 = strcat(tmp,'_VIVO_PARSED.dat');
    subjects1(x) = tmp2;
end


%% FILE NAME WHERE THE PROCESSED DATA WILL BE WRITTEN
FILENAME = subjects1;

for sheet = 1:length(subjects1)
    sheet
    [num,txt,raw] = xlsread(filename,sheet);
    
    
    %% EXTRACT TIME AND Y-DATA FROM EXCEL SHEET
    
    % FIND WHERE THE TIME COLUMN IS LOCATED IN THE EXCEL SHEET
    TF=strcmp(raw, raw(2,2)); % RAW(2,2)='Time (sec)'
    % raw(2,2)
    % find(TF)
    [row,col] = find(TF);
    colvivo_time = [col' col(end)+5]';% PUT ALL TIME STAMPS IN AN ARRAY
    %colvivo_time
    
    % FIND WHERE THE Y DATA IS LOCATED IN THE EXCEL SHEET
    % Y data is located in between time stamps
    n=6;
    for i=1:length(colvivo_time)-1
        colvivo_y((i-1)*n+1:n*i) = linspace(colvivo_time(i),colvivo_time(i+1),n);
    end
    %colvivo_y
    % remove time stamps from the data columns
    colvivo_y = setdiff(colvivo_y,colvivo_time);
    %colvivo_y
    
    % extract data and time stamps
    tvivo=raw(:,colvivo_time(1:end-1));
    %tvivo
    yvivo = raw(:,colvivo_y);
    %yvivo
    
    %size(tvivo,2)
    % PROCESS TIME AND DATA
    for i=1:size(tvivo,2) % extract data for each block (seated, suppine, etc...)
        i;
        % Change time to a running time (running cumulative sum)
        t_tmp = tvivo(:,i);
        fh = @(x) all(isnan(x(:)));
        t_tmp(cellfun(fh, t_tmp)) = [];
        t_tmp = t_tmp(3:end);
        % t_tmp
        time = cell2mat(t_tmp);
        % time
        time = [0; diff(time )*(24*60*60)];
        time =sum(triu(repmat(time',[prod(size(time')) 1])'))';       
        %data
        n = 4;
        k=1;
        for j=(i-1)*n+1:n*i
            j
            y_tmp = yvivo(:,j);
            %y_tmp
            fh = @(x) all(isnan(x(:)));
            y_tmp(cellfun(fh, y_tmp)) = [];
            y_tmp = y_tmp(2:end);
            y(:,k) = cell2mat(y_tmp);
            k=k+1;
        end
        time
        y
        % COLLECT DATA IN CELL ARRAY
        data2file{:,i}=[time y];
        
        %PLOT DATA
        hFig = figure;
        plot(time,y,'k-s','LineWidth',1,'MarkerEdgeColor','k',...
            'MarkerFaceColor','k',...
            'MarkerSize',3)
        xlabel('time[s]');
        set(hFig, 'Position', [300 300 1000 400])
        
        clear y;
        clear time;
    end
    
    % PREPARE data2file TO BE WRITTEN INTO AN EXTERNAL *.DAT FILE
    % Data varies in length from block to block (seated vs suppine vs etc...)
    % The idea is to write the whole data sets (all blocks) into one huge cell
    % array.
    
    intl = cellfun( @size, data2file, 'uni',false) ;
    for i=1:length(intl)
        rownum(i) = intl{i}(1) ;
        colnum(i) = intl{i}(2) ;
    end
    nRow = max(rownum) ;
    nCol = sum(colnum) ;
    % fill out a cell array
    content = cell( nRow, nCol ) ;
    for cId = 1 : length(data2file)
        ne = size( data2file{cId} ) ;
        content(1:ne(1),(cId-1)*ne(2)+1:ne(2)*cId) = num2cell(data2file{cId}(1:ne(1),1:ne(2))) ;
    end
    % convert into a cell array of printed (to string) content.
    contentStr = cellfun( @(x)sprintf('%f', x), content,'UniformOutput', false ) ;
    % Then we get the max string length per column. Note that we could skip this
    %operation if we wanted to enforce a fixed length format
    strlen = max( cellfun( @length, contentStr )) ;
    
    % find empty fields and replace them with a 'filler string'
    indempt=find(cellfun(@isempty,contentStr));
    contentStr(indempt)={'-999999999'};

    
    % WRITE DATA TO FILE
    fileID = fopen(strcat(dataDirName,FILENAME{sheet}),'w');
    format = sprintf( '%%%ds    ', strlen ) ;
    for rId = 1 : size( contentStr, 1 )
        fprintf( fileID, format, contentStr{rId,:} ) ;
        fprintf( fileID, '\r\n' ) ;
    end
    fclose( fileID ) ;
    
    clear  data2file
    close all
    
end

done = 'Done'