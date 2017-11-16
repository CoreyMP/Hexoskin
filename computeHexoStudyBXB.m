clear all
close all
clc


%%-------------------
%%INPUT

% AVERAGING WINDOW SIZE
windowSize_seconds = 30;

%-------------------
ALL_METRICS = {'VENTILATION', 'VT', 'BREATHING_FREQUENCY', 'HEART_RATE'};

ALL_CONDITIONS = {'6MIN_BASELINE1', 'INCREMENTAL', '6MIN_BASELINE2', 'CWR'};

dataDirName = 'HEXO_STUDY_BXB_DATA_PARSED\';
%writeDataTo = '_INDVS_DATA_VIVO_CALIBRATED\';
%mkdir(writeDataTo);

subjectsHexoStudy;

for x = 1:length(subjects)
    tmp = subjects(x);
    tmp2 = strcat(tmp,'_BXB_PARSED.dat');
    subjects1(x) = tmp2;
end

fileName_VIVO = subjects1;

col_time = [1 6 11 16];

for i = 1: length(fileName_VIVO)
    fileName_VIVO(i);
    M_VIVO = dlmread(strcat(dataDirName,fileName_VIVO{i}));
    store2 = 1;
            
    for jj = 1:length(ALL_CONDITIONS)
    
        CONDITION = ALL_CONDITIONS{jj};
        
        for kkk=1:length(ALL_METRICS)
            
            METRIC = ALL_METRICS{kkk};
            
            switch METRIC
                case 'VENTILATION'
                    col_num = [2     7    12    17];
                case 'VT'
                    col_num = [3    8    13    18];
                case 'BREATHING_RATE'
                    col_num = [4    9    14    19]; % 4=breathing rate 6MIN_BASLENE,
                case 'HEART_RATE'
                    col_num = [5    10    15    20];
            end
            
            col_data = col_num(jj);
        
            Y_VIVO = M_VIVO(:,col_data);
            indneg1=Y_VIVO <= -999999999;     % filter -99999999 data from file
            indneg2 = find(~indneg1);
            Y_VIVO = Y_VIVO(indneg2);
            
            time_VIVO = M_VIVO(:,col_time(jj));
            indneg3= time_VIVO < 0;
            indneg4=find(~indneg3);
            time_VIVO = time_VIVO(indneg4);
            
            %pointer = (kkk)*(jj)*3 - 11
            
            time =  time_VIVO;
            y = Y_VIVO;
            max = time(length(time));
            max2 = ceil(max/30);
            max3 = (max2+1)*30;
            timeEdge = 0:30:max3;
            iEdge = 1;
            count = 1;
            
            for ii = 1:length(time)
                if time(ii) >= timeEdge(iEdge) && time(ii) < timeEdge(iEdge + 1) && ii ~= length(time);
                    continue;
                elseif ii == length(time)
                    %ave = aveSum/count
                    dataStore(i, store2, iEdge,1) = timeEdge(iEdge+1);
                    dataStore(i, store2, iEdge, 2) = mean(y(count:ii));
                    dataStore(i, store2, iEdge, 3) = std(y(count:ii));
                    dataStore(i, store2, iEdge, 4) = std(y(count:ii))/sqrt(length(y(count:ii)));
                    %aveSum = 0;
                    count = ii;
                    iEdge = iEdge + 1;
                else
                    %ave = aveSum/count
                    dataStore(i, store2, iEdge, 1) = timeEdge(iEdge+1);
                    dataStore(i, store2, iEdge, 2) = mean(y(count:ii-1));
                    dataStore(i, store2, iEdge, 3) = std(y(count:ii-1));
                    dataStore(i, store2, iEdge, 4) = std(y(count:ii-1))/sqrt(length(y(count:ii-1)));
                    %aveSum = 0;
                    count = ii;
                    iEdge = iEdge + 1;
                end
            end
            %dataStore(i,store2,6,3)
            store2 = store2 + 1;
            
        end
    end
end

captionStr = 'Time,Mean,SD,SEM,';
for i = 2:16
   captionStr = strcat(captionStr,'Time,Mean,SD,SEM');
   if i ~= 16
       captionStr = strcat(captionStr,',');
   else
       captionStr = strcat(captionStr,'\r\n');
   end
end
caption = '6MIN_BASELINE1,,,,,,,,,,,,,,,,INCREMENTAL,,,,,,,,,,,,,,,,6MIN_BASELINE2,,,,,,,,,,,,,,,,CWR,,,,,,,,,,,,,,,,\r\n';
caption2 = 'Ventilation,,,,VT,,,,Breathing Frequency,,,,Heart Rate,,,,Ventilation,,,,VT,,,,Breathing Frequency,,,,Heart Rate,,,,Ventilation,,,,VT,,,,Breathing Frequency,,,,Heart Rate,,,,Ventilation,,,,VT,,,,Breathing Frequency,,,,Heart Rate,,,,\r\n';

for x = 1:length(subjects)
    tmp = subjects(x);
    tmp2 = strcat(tmp,'_BXB_COMPUTED.csv');
    subjects2(x) = tmp2;
end

fileName_VIVO = subjects2;


writeDir = 'HEXO_STUDY_BXB_DATA_COMPUTED\';
mkdir(writeDir);
test = dataStore(:,1,:,1);
for i = 1: length(fileName_VIVO)
    %contentStr(1) = captionStr;
    fID = strcat(writeDir,fileName_VIVO{i});
    fileID = fopen(fID,'w');
    fprintf(fileID, caption);
    fprintf(fileID,caption2);
    fprintf(fileID, captionStr);
    for iii = 1:size(test,3)-1
        contentStr = '';
        for ii = 1: 16
            for iiii = 1:4
                if dataStore(i,ii,iii,iiii) == 0 && dataStore(i,ii,iii,1) == 0
                    contentStr = strcat(contentStr,',');
                else
                    T = dataStore(i,ii,iii,iiii);
                    s = num2str(T);
                    contentStr = strcat(contentStr, s);
                    if ii == 16 && iiii == 4
                        continue;
                    else
                        contentStr = strcat(contentStr, ',');
                    end
                end 
            end
        end
        contentStr = strcat(contentStr,'\r\n');
        fileID;
        fprintf(fileID, contentStr);
    end
    fclose(fileID);
end 
done = 'Done'