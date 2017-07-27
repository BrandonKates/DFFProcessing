clear;
close all;
%%Uses a single json file that contains only the centroids, and loads in
%%dff, Cd, and Sp mat files from directory
% Json files are assumed to have centroid field, and nothing else is
% assumed

%% Find the json file
[foldername, dir_nm] = uigetfile('.json');
fullpath = fullfile(dir_nm,foldername); % Set the file name using this variable

%% Load in variables for dff extraction from same directory.

if(exist(fullfile(dir_nm, 'Fdf.mat'),'file'))
    load(fullfile(dir_nm, 'Fdf.mat'))
end
if(exist(fullfile(dir_nm, 'Cd.mat'),'file'))
    load(fullfile(dir_nm, 'Cd.mat'))
end
if(exist(fullfile(dir_nm, 'Sp.mat'),'file'))
    load(fullfile(dir_nm, 'Sp.mat'))
end


%% Create a new struct with neuron data (nid, dff, Cd, and Sp) concatenated by time
Fdf_concat = [];
Sp_concat = [];
Cd_concat = [];
for i = 1:length(F_df)
    if(exist('F_df','var'))
        Fdf_concat = horzcat(Fdf_concat, cell2mat(F_df(i)));
    end
    if(exist('Sp','var'))
        Sp_concat = horzcat(Sp_concat, cell2mat(Sp(i)));
    end
    if(exist('Cd','var'))
        Cd_concat = horzcat(Cd_concat, cell2mat(Cd(i)));
    end
end

newNeurons = struct('nid',[],'dff',[],'Cd',[],'Sp',[]);
neurons = jsonread(fullpath);
for i = 1:length(neurons.jmesh)
    newNeurons(i).nid = i;
    newNeurons(i).dff = Fdf_concat(i,:);
    newNeurons(i).Sp = Sp_concat(i,:);
    newNeurons(i).Cd = Cd_concat(i,:);
end

%% Initialize variables
pullTimes = horzcat([1144 1175],[1515 1545],[1700 1735],[2445 2475],[3035 3065],[3465 3495]);% One input 

pTA = 100; % frames before and after pull that should be included in the average
xpoints = (1:length([newNeurons.dff]));

seconds = true;
framerate = 1;
if seconds
    framerate = 30.31;
end


badIndices = vertcat(find(vertcat(newNeurons.dff) > 4), find(vertcat(newNeurons.dff) < -1));
dff = vertcat(newNeurons.dff);
Cd = vertcat(newNeurons.Cd);
Sp = vertcat(newNeurons.Sp);
dff(badIndices) = 0;


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