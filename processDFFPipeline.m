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
    newNeurons(i).dff = Fdf_concat(i,:)';
    newNeurons(i).Sp = Sp_concat(i,:)';
    newNeurons(i).Cd = Cd_concat(i,:)';
end

%% Initialize variables
pullTimes = horzcat([1144 1175],[1515 1545],[1700 1735],[2445 2475],[3035 3065],[3465 3495]);% One input 
pullTimes2 = 3600 + horzcat([135,165],[360,400],[730,770]);
pullTimes3 = 7200 + horzcat([963,995],[1308,1340],[1544,1574],[1689,1719]);
pullTimes = [pullTimes,pullTimes2,pullTimes3];

pTA = 100; % frames before and after pull that should be included in the average
xpoints = (1:length([newNeurons.Cd]));

seconds = true;
framerate = 1;
if seconds
    framerate = 30.305;
end


neuronClass = csvread('\Users\User\Desktop\717\neuronClassification717.csv');

active = find(neuronClass==1);
quiesc = find(neuronClass==2);
indisc = find(neuronClass==3);

badIndices = vertcat(find(vertcat(newNeurons.dff) > 4), find(vertcat(newNeurons.dff) < -1));
dff = horzcat(newNeurons.dff);
Cd = horzcat(newNeurons.Cd);
Sp = horzcat(newNeurons.Sp);
dff(badIndices) = 0;

pulls= struct('pullNum',[],'pullFrames',[],'average',[]);
pullNum = 1;
for i = 1:2:length(pullTimes)
    thisPull = Cd(pullTimes(i) - pTA : pullTimes(i+1) + pTA,:);
    meanPull = mean(thisPull,2);
    pulls(pullNum).pullNum = pullNum;
    pulls(pullNum).pullFrames = [pullTimes(i) pullTimes(i+1)];
    pulls(pullNum).average = meanPull;
    pullNum = pullNum + 1;
end

%% Start by looking at all neurons plotted on same plot and stacked 
co = ...
    [0        0.4470    0.7410;
    0.8500    0.3250    0.0980;
    0.9290    0.6940    0.1250;
    0.4940    0.1840    0.5560;
    0.4660    0.6740    0.1880;
    0.3010    0.7450    0.9330;
    0.6350    0.0780    0.1840];
% Plot shows all neurons individually plotted on same frame
figure;
for i = 1:length(newNeurons)
    plot(newNeurons(i).Cd)
    hold on;
end
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2),[0 15],'b')     
end
%% Plot shows all neuron plots stacked.
figure;
for i = 1:length(newNeurons)
    plot(xpoints/framerate, newNeurons(i).Cd + i)
    hold on;
end
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 length(newNeurons)+1],'b')     
end
nvs = gca;
nvs.XTick = 0:50:max(xpoints/framerate);
nvs.YTick = 0:10:length(newNeurons);
xlabel('Time (seconds)');
ylabel('Neuron ID');

set(gca,'LooseInset',get(gca,'TightInset'));

%print -painters -dpng -r600 /Users/User/Desktop/717/allneurons3D.png
%% Population, Active, Quiescent, Indiscriminant Averages
figure;
plot(xpoints/framerate, mean([newNeurons.Cd],2)+3, 'col', co(1,:)) % Population Average
hold on;
plot(xpoints/framerate, mean([newNeurons(active).Cd],2)+2, 'col', co(2,:)) % Active Average

plot(xpoints/framerate, mean([newNeurons(quiesc).Cd],2)+1, 'col', co(3,:)) % Quiescent Average

plot(xpoints/framerate, mean([newNeurons(indisc).Cd],2), 'col', co(4,:)) % Indiscriminant Active Average

lgd = legend(['Population Average (n=' num2str(length(newNeurons)) ')'], ...
    ['Active Average (n=' num2str(length(active)) ')'], ...
    ['Quiescent Average (n=' num2str(length(quiesc)) ')'], ...
    ['Indiscriminant Average (n=' num2str(length(indisc)) ')']);
%plot(xpoints/framerate, [newNeurons(active).Cd]+2, 'color', [0,0,0]+0.8)
%plot(xpoints/framerate, mean([newNeurons(active).Cd],2)+2, 'col', co(2,:)) % Active Average
lgd.FontSize = 14;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 3.5],'b')     
end
set(gca,'YTick',[])
xlabel('Time (seconds)');
set(gca,'LooseInset',get(gca,'TightInset'));

%print -painters -dpng -r600 /Users/User/Desktop/717/neuronClasses3D.png

%% Plot All Neurons
% plot(xpoints/framerate,[newNeurons.Cd],'color',[0,0,0]+0.8)
figure;
plot(xpoints/framerate, [newNeurons(active).Cd]) % Active Neurons in this file
hold on;
plot(xpoints/framerate, mean([newNeurons(active).Cd],2),'g')
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

%% Plot Active
figure;
plot(xpoints/framerate, [newNeurons(active).Cd]) % Active Neurons in this file
% Plot vertical bars
hold on;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 2],'b')     
end
hold on;
plot(xpoints/framerate, mean([newNeurons(active).Cd],2),'g')

%% Stack Active
figure;
for i=active
    plot(xpoints/framerate, [newNeurons(active).Cd])
end
plot(xpoints/framerate, mean([newNeurons(active).Cd],2))
hold on;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2)/framerate,[0 1],'b')     
end

pullTimesMod(1:2:length(pullTimes))=pullTimes(1:2:length(pullTimes)) - pTA;
pullTimesMod(2:2:length(pullTimes))=pullTimes(2:2:length(pullTimes)) + pTA;

dffActive=[newNeurons(active).Cd];
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



%% Find active, quiescent, indiscriminant automatically.
%for i = 1:100
    figure;
    plot(xp, Sp(pullTimes(1)-100:pullTimes(2)+93,i),'r')
    hold on;
    plot([frames,frames],[0,0.4],'b')
    plot([(pTA+35)/framerate,(pTA+35)/framerate],[0,0.4],'b')
    legend(int2str(i))
    pause(2);
    %close;
%end

%% Plot an invidual neuron with pullframe bars - Deconvolved
%nnum=5;
figure('units','normalized','outerposition',[0 0 1 1])
lineinit = plot(Cd(:,nnum));
hold on;
for i = 1:length(pullTimes)
        plot(repmat(pullTimes(i),1,2),[0 5],'b')     
end
lineinit.Visible = 'Off';
for nnum = 1:size(Cd,2)
    line = plot(Cd(:,nnum));
    legend(num2str(nnum));
    pause();
    line.Visible = 'Off';
end

%% Plot an invidual neuron with pullframe bars - Spike
figure;
plot(1:5000, Sp(1:5000,nnum))
hold on;
for i = 1:length(pullTimes)-10
        plot(repmat(pullTimes(i),1,2),[0 2],'b')     
end