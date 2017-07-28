clear;
close all;
%% READ IN FILES AUTOMATICALLY, pick as many json files as you want.
% Implement automatically choosing files using the filesystem. (Finds all
% json files in subdirectories).

%foldername = '/Users/Brandon/Documents/Brandon Everything/Burke Research ''17/Dr. Hollis Lab/2photonAverage/';   %Change to folder above where json file exist for each video you want to combine.
%
manual = false;
[foldername, dir_nm] = uigetfile('.json');
%foldername = 'F:\Test_run_pipeline_717';

files = subdir(fullfile(dir_nm,'*.json')); % list of filenames (will search all subdirectories)
jsonFiles = [];
for i = 1:length(files)
    jsonFiles = [jsonFiles jsonread(files(i).name)];
end

% Json files are assumed to have centroid, dff fields
distThresh = 8;

%% For one long file enable this only:
%[foldername, dir_nm] = uigetfile('.json');
filename = fullfile(dir_nm,foldername); % Set the file name using this variable
one_long_file = true;
if one_long_file
    newNeurons = struct('nid',[],'dff',[]);
    neurons = jsonread(filename);
    for i = 1:length(neurons.jmesh)
        newNeurons(i).nid = i;
        newNeurons(i).dff = neurons.jmesh(i).dff;
    end
    
    pullTimes = horzcat([1144 1175],[1515 1545],[1700 1735],[2445 2475],[3035 3065],[3465 3495]);
    
    pTA = 100; % frames before and after pull that should be included in the average
    xpoints = (1:length([newNeurons.dff]));
    
    seconds = true;
    framerate = 1;
    if seconds
        framerate = 30.31;
    end
    
    dff=[newNeurons.dff];
    pulls= struct('pullNum',[],'pullFrames',[],'average',[]);
    pullNum = 1;
    for i = 1:2:length(pullTimes)
        thisPull = dff(pullTimes(i) - pTA : pullTimes(i+1) + pTA,:);
        meanPull = mean(thisPull,2);
        pulls(pullNum).pullNum = pullNum;
        pulls(pullNum).pullFrames = [pullTimes(i) pullTimes(i+1)];
        pulls(pullNum).average = meanPull;
        pullNum = pullNum + 1;
    end
    
    % Plot All Neurons
    % plot(xpoints/framerate,[newNeurons.dff],'color',[0,0,0]+0.8)
    plot(xpoints/framerate, [newNeurons([5 6 10 12 14]).dff]) % Active Neurons in this file
    hold on;
    plot(xpoints/framerate, mean([newNeurons([5 6 10 12 14]).dff],2),'g')
    hold on;
    % plot the pullFrames as vertical bars on the graph
    for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 2],'b')     
    end
    %plot the averages of the pullframes
    for i = 1:length(pulls)
        pull = pulls(i).pullFrames;
        plot((pull(1)-pTA : pull(2)+pTA)/framerate, pulls(i).average,'r')
        hold on;
    end
    xlabel('Time (s)')
end

active = [5 6 10 12 14];
quiesc = [1 2 3 4 11 16];
indisc = [7 8 9 13 15];

%% Plot Active
figure;
plot(xpoints/framerate, [newNeurons(active).dff]) % Active Neurons in this file
% Plot vertical bars
hold on;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 2],'b')     
end
hold on;
plot(xpoints/framerate, mean([newNeurons(active).dff],2),'g')

%% Stack Active
for i=active
    plot(xpoints/framerate, [newNeurons(active).dff])
end
plot(xpoints/framerate, mean([newNeurons(active).dff],2))
hold on;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 1],'b')     
end

pullTimesMod(1:2:length(pullTimes))=pullTimes(1:2:length(pullTimes)) - pTA;
pullTimesMod(2:2:length(pullTimes))=pullTimes(2:2:length(pullTimes)) + pTA;

dffActive=[newNeurons(active).dff];
pullFrameLength = 225;

neuronPulls = [];
for i = 1:2:length(pullTimesMod)
    addFrames = pullFrameLength - length(pullTimesMod(i):pullTimesMod(i+1));
    neuronPulls = horzcat(neuronPulls, dffActive(pullTimesMod(i):(pullTimesMod(i+1) + addFrames),:));
end

neuronPullsAvg = [];
for i = 1:length([newNeurons(active)])
    neuronPullsSize = size(neuronPulls);
    neuronPullsLength = neuronPullsSize(2);
    neuronPullsAvg = horzcat(neuronPullsAvg, mean(neuronPulls(:,i:length([newNeurons(active)]):neuronPullsLength),2));
end

%% Individual Neurons averaged to one mouse pull.
figure;
xp = (1:length(neuronPullsAvg))/framerate;
plot(xp, neuronPullsAvg)
hold on;
frames = pTA / framerate;
plot([frames,frames],[0,0.6],'b')
plot([(pTA+35)/framerate,(pTA+35)/framerate],[0,0.6],'b')

%% Total Average in one pull period
figure;
plot(xp, mean(neuronPullsAvg,2),'r')
hold on;
plot([frames,frames],[0,0.4],'b')
plot([(pTA+35)/framerate,(pTA+35)/framerate],[0,0.4],'b')

%% Plot all averages

plot(xpoints/framerate, mean([newNeurons.dff],2)+3) % Population Average
hold on;
plot(xpoints/framerate, [newNeurons(active).dff]+2, 'color', [0,0,0]+0.8)
plot(xpoints/framerate, mean([newNeurons(active).dff],2)+2) % Active Average

plot(xpoints/framerate, mean([newNeurons(quiesc).dff],2)+1) % Quiescent Average

plot(xpoints/framerate, mean([newNeurons(indisc).dff],2)) % Indiscriminant Active Average

legend('Population Average','Active Average', 'Quiescent Average', 'Indiscriminant Average')

for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 3.5],'b')     
end


%% Updates the jmesh to have a nid field with the neuron index matched between files.
% Also attaches neurons with same nid in a new file with just neurons nid
% and dff values (as a matrix).
[neurons, newNeurons] = indexNeurons(jsonFiles, distThresh);


%% Plot averages of neurons between files

% Plot shows all neurons individually plotted on same frame
for i = 1:length(newNeurons)
    plot(mean(newNeurons(i).dff,2))% + i)
    hold on;
end

% Plot shows all neuron plots stacked.
figure;
for i = 1:length(newNeurons)
    plot(mean(newNeurons(i).dff,2) + i)
    hold on;
end


%% Plot as one continuous file
figure;
for i=1:length(newNeurons)
    plot(reshape(newNeurons(i).dff, numel(newNeurons(i).dff),1) + 2*(i-1))
    hold on;
end