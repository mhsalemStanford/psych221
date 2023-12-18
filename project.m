curPath = pwd
cd '../../isetcam';
isetPath(pwd);
cd(curPath);
tic
oi = oiCreate;
sensor = sensorCreate;
ip = ipCreate;
scoreClasses = 5;
% Set the Images Folder Here.
imageFolder = "\n02088364-beagle";

% Set a flag for the paramater sweep.
fNumber_focLen_sweep_flag = false;
focLen_expTime_sweep_flag = false;
readNoise_sweep_flag = false;
expTime_sweep_flag = false;

% Set the number of parameters that will be sweeped.
parameters_sweep_len = 3;

% The set of the pre-trained networks on ImageNet. 
nets = [googlenet squeezenet shufflenet mobilenetv2 efficientnetb0];
nets_name = ["googlenet" "squeezenet" "shufflenet" "mobilenetv2" "efficientnetb0"];

fNumberList = [1.0 1.4 2 4 5.6 8 11 16 22 32];
focLenList = [0.015 0.020 0.028 0.035 0.050 0.070 0.085 0.135 0.200 0.300];
fnFocLenList = [focLenList(1) focLenList(2) focLenList(4) focLenList(5)];
readNoiseList = [1, 10, 50, 100, 200];
expTimeList = [0.005 0.010 0.020 0.040 0.080];

fNumber_focLen_data = [];
focLen_expTime_data = [];
readNoise_data = [];
expTime_data = [];

fnumber_focLen_table = table;
focLen_expTime_table = table;
read_noise_table = table;
expTime_table = table;

% Iterate thru the Camera paramters that will be modified.
for paramIdx = 3
    : parameters_sweep_len
    % Sets the flag for the parameter that will be sweeped.
    if paramIdx == 1
        fNumber_focLen_sweep_flag = true;
    elseif paramIdx == 2
        focLen_expTime_sweep_flag = true;
    elseif paramIdx == 3
        readNoise_sweep_flag = true;
    elseif paramIdx == 4
        expTime_sweep_flag = true;
    end
    
    % Check if the f-number will be sweeped.
    if fNumber_focLen_sweep_flag == true
        % Sweep the f-numbers.
        for fnIdx = 1:length(fNumberList)
            % Create default obejects.
            oi = oiCreate;
            sensor = sensorCreate;
            ip = ipCreate;
            
            % Modify the fNumber parameter only.
            oi.optics.fNumber = fNumberList(fnIdx);

            % Sweep the focal length for the f-numbers.
            for flIdx = 1:length(fnFocLenList)

                % Modify the fNumber parameter only.
                oi.optics.focalLength = fnFocLenList(flIdx);

                disp(strcat("F-Number = ", num2str(fNumberList(fnIdx)), ", Focal Length = ", num2str(fnFocLenList(flIdx))));

                % Run irClassify that generates the images depending on the
                % Camera Charestristics and classify the images using googlenet,  
                % squeezenet, shufflenet, mobilenetv2, and efficientnetb0 networks.
                [orgScoreStats, orgScoreTable, tstScoreStats, tstScoreTable] = irClassify('imageFolder', imageFolder, 'oi', oi, 'sensor', sensor, 'ip', ip, 'scoreClasses', scoreClasses);
    
                % Creakte a sub-folder to store the data.
                subFolder = strcat(char(imageFolder), '\fN', num2str(fNumberList(fnIdx)), '_focalLen', num2str(fnFocLenList(flIdx)));
                mkdir(subFolder);
    
                % Iterate thru the networks to extract each network
                % information.
                for netIdx = 1: length(nets_name)
                    % Extract the label table of the network and store the info
                    % in a csv file. 
                    scoreIdx =   (netIdx-1)*4 + 1;
                    scoreTable = orgScoreTable(:, [scoreIdx:scoreIdx+3]);
                    fileName = strcat(subFolder, '\orgScoreTable_', char(nets_name(netIdx)), '.csv');
                    writematrix(scoreTable, fileName);
                    scoreTable = tstScoreTable(:, [scoreIdx:scoreIdx+3]);
                    fileName = strcat(subFolder, '\tstScoreTable_', char(nets_name(netIdx)), '.csv');
                    writematrix(scoreTable, fileName);
    
                    % Extract the stats of the network and append the info to a
                    % text file.
                    resultFile = strcat(subFolder, '\nets_results.txt');
                    statsIdx = (netIdx-1)*3 + 1;
                    fid = fopen(resultFile, 'a+');
                    stats = cell2mat(orgScoreStats(:, [statsIdx:statsIdx+2]));
                    orgPerc = (stats(1)/stats(2))*100;
                    fprintf(fid, 'Original Images Percentage: %f on %d images using %s as a classifier\n', orgPerc, stats(3), nets_name(netIdx));
                    stats = cell2mat(tstScoreStats(:, [statsIdx:statsIdx+2]));
                    tstPerc = (stats(1)/stats(2))*100;
                    fprintf(fid, 'Generated Images Percentage: %f on %d images using %s as a classifier\n', tstPerc, stats(3), nets_name(netIdx));
                    fclose(fid);

                    % Store the data in a table to plot it.
                    fNumber_focLen_data = [fNumber_focLen_data; fNumberList(fnIdx) fnFocLenList(flIdx) nets_name(netIdx) orgPerc tstPerc];
                end
                % Copy the IP folder and rename it with the fN info.
                oldFolderName = strcat(char(imageFolder), '\ip');
                newFolderName = strcat(char(subFolder), '\ip');
                copyfile(oldFolderName, newFolderName)
    
                % Copy the OpticalImages folder and rename it with the fN info.
                % oldFolderName = strcat(char(imageFolder), '\opticalimage');
                % newFolderName = strcat(char(subFolder), '\opticalimage');
                % copyfile(oldFolderName, newFolderName)
            end
        end
        % Generate a table of the data.
        fnumber_focLen_table.f_number = str2double(fNumber_focLen_data(:, [1]));
        fnumber_focLen_table.focal_length = str2double(fNumber_focLen_data(:, [2]));
        fnumber_focLen_table.netowrks = fNumber_focLen_data(:, [3]);
        fnumber_focLen_table.org_accuracy = str2double(fNumber_focLen_data(:, [4]));
        fnumber_focLen_table.gen_accuracy = str2double(fNumber_focLen_data(:, [5]));
        % fnumber_focLen_table = table(f_number, focal_length, netowrks, org_accuracy, gen_accuracy);

        % Set the f-number sweep flag to false since it is done.
        fNumber_focLen_sweep_flag = false;

    % Check if the focal length will be sweeped.
    elseif focLen_expTime_sweep_flag == true
        % Sweep the focal length from 3.9 mm to 19.5 mm with a step of 4 mm.
        for flIdx = 1:length(focLenList)-3
            % Create default obejects.
            oi = oiCreate;
            sensor = sensorCreate;
            ip = ipCreate;

            % Modify the focalLength parameter.
            oi.optics.focalLength = focLenList(flIdx);

            % Sweep the focal length for the f-numbers.
            for expIdx = 1:2
                if expIdx == 1
                    % Set the expousre time < 1/focalLen
                    expTime = (1/(1000*focLenList(flIdx))) - 0.003;
                else
                    % Set the expousre time > 1/focalLen
                    expTime = (1/(1000*focLenList(flIdx))) + 0.003;
                end

                % Modify the exposure time parameter.
                sensor = sensorSet(sensor,'exposure time', expTime);

                disp(strcat("Focal Length = ", num2str(focLenList(flIdx)), ", Exposure Time = ", num2str(expTime)));

                % Run irClassify that generates the images depending on the
                % Camera Charestristics and classify the images using googlenet,  
                % squeezenet, shufflenet, mobilenetv2, and efficientnetb0 networks.
                [orgScoreStats, orgScoreTable, tstScoreStats, tstScoreTable] = irClassify('imageFolder', imageFolder, 'oi', oi, 'sensor', sensor, 'ip', ip, 'scoreClasses', scoreClasses);
    
                % Creakte a sub-folder to store the data.
                subFolder = strcat(char(imageFolder), '\focalLen', num2str(focLenList(flIdx)), '_expTime', num2str(expTime));
                mkdir(subFolder);
    
                % Iterate thru the networks to extract each network
                % information.
                for netIdx = 1: length(nets_name)
                    % Extract the label table of the network and store the info
                    % in a csv file. 
                    scoreIdx =   (netIdx-1)*4 + 1;
                    scoreTable = orgScoreTable(:, [scoreIdx:scoreIdx+3]);
                    fileName = strcat(subFolder, '\orgScoreTable_', char(nets_name(netIdx)), '.csv');
                    writematrix(scoreTable, fileName);
                    scoreTable = tstScoreTable(:, [scoreIdx:scoreIdx+3]);
                    fileName = strcat(subFolder, '\tstScoreTable_', char(nets_name(netIdx)), '.csv');
                    writematrix(scoreTable, fileName);
    
                    % Extract the stats of the network and append the info to a
                    % text file.
                    resultFile = strcat(subFolder, '\nets_results.txt');
                    statsIdx = (netIdx-1)*3 + 1;
                    fid = fopen(resultFile, 'a+');
                    stats = cell2mat(orgScoreStats(:, [statsIdx:statsIdx+2]));
                    orgPerc = (stats(1)/stats(2))*100;
                    fprintf(fid, 'Original Images Percentage: %f on %d images using %s as a classifier\n', orgPerc, stats(3), nets_name(netIdx));
                    stats = cell2mat(tstScoreStats(:, [statsIdx:statsIdx+2]));
                    tstPerc = (stats(1)/stats(2))*100;
                    fprintf(fid, 'Generated Images Percentage: %f on %d images using %s as a classifier\n', tstPerc, stats(3), nets_name(netIdx));
                    fclose(fid);

                    % Store the data in a table to plot it.
                    focLen_expTime_data = [focLen_expTime_data; focLenList(flIdx) expTime nets_name(netIdx) orgPerc tstPerc];
                end
                % Copy the IP folder and rename it with the focalLen info.
                oldFolderName = strcat(char(imageFolder), '\ip');
                newFolderName = strcat(char(subFolder), '\ip');
                copyfile(oldFolderName, newFolderName)
    
                % Copy the Optical Images folder and rename it with the
                % focalLen info.
                % oldFolderName = strcat(char(imageFolder), '\opticalimage');
                % newFolderName = strcat(char(subFolder), '\opticalimage');
                % copyfile(oldFolderName, newFolderName)
            end
        end
        % Generate a table of the data.
        focLen_expTime_table.focal_length = str2double(focLen_expTime_data(:, [1]));
        focLen_expTime_table.exposure_time = str2double(focLen_expTime_data(:, [2]));
        focLen_expTime_table.netowrks = focLen_expTime_data(:, [3]);
        focLen_expTime_table.org_accuracy = str2double(focLen_expTime_data(:, [4]));
        focLen_expTime_table.gen_accuracy = str2double(focLen_expTime_data(:, [5]));
        % focLen_expTime_table = table(focal_length, exposure_time, netowrks, org_accuracy, gen_accuracy);

        % Set the focal length sweep flag to false since it is done.
        focLen_expTime_sweep_flag = false;

    % Check if the focal length will be sweeped.
    elseif readNoise_sweep_flag == true
        % Sweep the focal length from 3.9 mm to 19.5 mm with a step of 4 mm.
        for noiseIdx = 1:length(readNoiseList)
            % Create default obejects.
            oi = oiCreate;
            sensor = sensorCreate;
            ip = ipCreate;

            % Modify the Read Noise parameter.
            sensor = sensorSet(sensor,'pixel read noise electrons', readNoiseList(noiseIdx));

            disp(strcat("Read Noise = ", num2str(readNoiseList(noiseIdx))));

            % Run irClassify that generates the images depending on the
            % Camera Charestristics and classify the images using googlenet,  
            % squeezenet, shufflenet, mobilenetv2, and efficientnetb0 networks.
            [orgScoreStats, orgScoreTable, tstScoreStats, tstScoreTable] = irClassify('imageFolder', imageFolder, 'oi', oi, 'sensor', sensor, 'ip', ip, 'scoreClasses', scoreClasses);

            % Creakte a sub-folder to store the data.
            subFolder = strcat(char(imageFolder), '\readNoise', num2str(readNoiseList(noiseIdx)));
            mkdir(subFolder);

            % Iterate thru the networks to extract each network
            % information.
            for netIdx = 1: length(nets_name)
                % Extract the label table of the network and store the info
                % in a csv file. 
                scoreIdx =   (netIdx-1)*4 + 1;
                scoreTable = orgScoreTable(:, [scoreIdx:scoreIdx+3]);
                fileName = strcat(subFolder, '\orgScoreTable_', char(nets_name(netIdx)), '.csv');
                writematrix(scoreTable, fileName);
                scoreTable = tstScoreTable(:, [scoreIdx:scoreIdx+3]);
                fileName = strcat(subFolder, '\tstScoreTable_', char(nets_name(netIdx)), '.csv');
                writematrix(scoreTable, fileName);

                % Extract the stats of the network and append the info to a
                % text file.
                resultFile = strcat(subFolder, '\nets_results.txt');
                statsIdx = (netIdx-1)*3 + 1;
                fid = fopen(resultFile, 'a+');
                stats = cell2mat(orgScoreStats(:, [statsIdx:statsIdx+2]));
                orgPerc = (stats(1)/stats(2))*100;
                fprintf(fid, 'Original Images Percentage: %f on %d images using %s as a classifier\n', orgPerc, stats(3), nets_name(netIdx));
                stats = cell2mat(tstScoreStats(:, [statsIdx:statsIdx+2]));
                tstPerc = (stats(1)/stats(2))*100;
                fprintf(fid, 'Generated Images Percentage: %f on %d images using %s as a classifier\n', tstPerc, stats(3), nets_name(netIdx));
                fclose(fid);

                % Store the data in a table to plot it.
                readNoise_data = [readNoise_data; readNoiseList(noiseIdx) nets_name(netIdx) orgPerc tstPerc];
            end

            % Copy the IP folder and rename it with the focalLen info.
            oldFolderName = strcat(char(imageFolder), '\ip');
            newFolderName = strcat(char(subFolder), '\ip');
            copyfile(oldFolderName, newFolderName)

            % Copy the Optical Images folder and rename it with the
            % focalLen info.
            % oldFolderName = strcat(char(imageFolder), '\opticalimage');
            % newFolderName = strcat(char(subFolder), '\opticalimage');
            % copyfile(oldFolderName, newFolderName)
        end
        % Generate a table of the data.
        read_noise_table.read_noise = str2double(readNoise_data(:, [1]));
        read_noise_table.netowrks = readNoise_data(:, [2]);
        read_noise_table.org_accuracy = str2double(readNoise_data(:, [3]));
        read_noise_table.gen_accuracy = str2double(readNoise_data(:, [4]));

        % Set the focal length sweep flag to false since it is done.
        readNoise_sweep_flag = false;
    elseif expTime_sweep_flag == true
        % Sweep the focal length from 3.9 mm to 19.5 mm with a step of 4 mm.
        for expIdx = 1:length(expTimeList)
            % Create default obejects.
            oi = oiCreate;
            sensor = sensorCreate;
            ip = ipCreate;

           % Modify the exposure time parameter.
            sensor = sensorSet(sensor,'exposure time', expTimeList(expIdx));

            disp(strcat("Exposure Time = ", num2str(expTimeList(expIdx))));

            % Run irClassify that generates the images depending on the
            % Camera Charestristics and classify the images using googlenet,  
            % squeezenet, shufflenet, mobilenetv2, and efficientnetb0 networks.
            [orgScoreStats, orgScoreTable, tstScoreStats, tstScoreTable] = irClassify('imageFolder', imageFolder, 'oi', oi, 'sensor', sensor, 'ip', ip, 'scoreClasses', scoreClasses);

            % Creakte a sub-folder to store the data.
            subFolder = strcat(char(imageFolder), '\expTime', num2str(expTimeList(expIdx)));
            mkdir(subFolder);

            % Iterate thru the networks to extract each network
            % information.
            for netIdx = 1: length(nets_name)
                % Extract the label table of the network and store the info
                % in a csv file. 
                scoreIdx =   (netIdx-1)*4 + 1;
                scoreTable = orgScoreTable(:, [scoreIdx:scoreIdx+3]);
                fileName = strcat(subFolder, '\orgScoreTable_', char(nets_name(netIdx)), '.csv');
                writematrix(scoreTable, fileName);
                scoreTable = tstScoreTable(:, [scoreIdx:scoreIdx+3]);
                fileName = strcat(subFolder, '\tstScoreTable_', char(nets_name(netIdx)), '.csv');
                writematrix(scoreTable, fileName);

                % Extract the stats of the network and append the info to a
                % text file.
                resultFile = strcat(subFolder, '\nets_results.txt');
                statsIdx = (netIdx-1)*3 + 1;
                fid = fopen(resultFile, 'a+');
                stats = cell2mat(orgScoreStats(:, [statsIdx:statsIdx+2]));
                orgPerc = (stats(1)/stats(2))*100;
                fprintf(fid, 'Original Images Percentage: %f on %d images using %s as a classifier\n', orgPerc, stats(3), nets_name(netIdx));
                stats = cell2mat(tstScoreStats(:, [statsIdx:statsIdx+2]));
                tstPerc = (stats(1)/stats(2))*100;
                fprintf(fid, 'Generated Images Percentage: %f on %d images using %s as a classifier\n', tstPerc, stats(3), nets_name(netIdx));
                fclose(fid);

                % Store the data in a table to plot it.
                expTime_data = [expTime_data; expTimeList(expIdx) nets_name(netIdx) orgPerc tstPerc];
            end

            % Copy the IP folder and rename it with the focalLen info.
            oldFolderName = strcat(char(imageFolder), '\ip');
            newFolderName = strcat(char(subFolder), '\ip');
            copyfile(oldFolderName, newFolderName)

            % Copy the Optical Images folder and rename it with the
            % focalLen info.
            % oldFolderName = strcat(char(imageFolder), '\opticalimage');
            % newFolderName = strcat(char(subFolder), '\opticalimage');
            % copyfile(oldFolderName, newFolderName)
        end
        % Generate a table of the data.
        expTime_table.exposure_time = str2double(expTime_data(:, [1]));
        expTime_table.netowrks = expTime_data(:, [2]);
        expTime_table.org_accuracy = str2double(expTime_data(:, [3]));
        expTime_table.gen_accuracy = str2double(expTime_data(:, [4]));

        % Set the Exposure Length sweep flag to false since it is done.
        expTime_sweep_flag = false;
    end
end

% Save Variables to mat file
% fnumber_focLen_table = table;
% focLen_expTime_table = table;
% read_noise_table = table;
save(strcat(imageFolder,"\myFile.mat"), "fNumber_focLen_data", "focLen_expTime_data", "readNoise_data", "expTime_data", "fnumber_focLen_table", "focLen_expTime_table", "read_noise_table", "expTime_table", "-v7.3", "-nocompression")
toc