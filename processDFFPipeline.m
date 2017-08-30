clear;
close all;
%%Uses a single json file that contains only the centroids, and loads in
%%dff, Cd, and Sp mat files from directory

%function [ newNeurons, fluorescenceData, classifications, binaryPullTimes,options] = processDFFInitVars(dir, pullFrames, fr, autoClassifyNeurons, pTA)
%[newNeurons,fluorescenceData,classifications,binaryPullTimes,pulls,options] = processDFFInitVars([],[1 2],1,0,100);

%% Initialize variables
pullFrames = horzcat([1144 1175],[1515 1545],[1700 1735],[2445 2475],[3035 3065],[3465 3495]);% One input 
pullFrames = horzcat(pullFrames, 3600 + horzcat([135,165],[360,400],[730,770]));
pullFrames = horzcat(pullFrames, 7200 + horzcat([963,995],[1308,1340],[1544,1574],[1689,1719]));

%dir = '/Users/Brandon/Documents/Brandon Everything/Burke Research ''17/Dr. Hollis Lab/717and720/#717_7.11.17/'; % 
dir = '';
%pullFrames = [];
numVideos = 10;


fr = 30.305; % Set the framerate for graphing, 1=frames
autoClassifyNeurons = false;
pTA = 100; % frames before and after pull that should be included in the average

[newNeurons,fluorescenceData,classifications,binaryPullTimes,pulls,options] = processDFFInitVars(dir,pullFrames,fr,autoClassifyNeurons,pTA);

% Unpack Data from function call
numFrames = options.numFrames;
numNeurons = options.numNeurons;
xpoints = options.xpoints;
framerate = options.framerate;
pTA = options.pTA;
%
Fdf = fluorescenceData.Fdf;
Cd = fluorescenceData.Cd;
Sp = fluorescenceData.Sp;
%
% Choose which data we want to use for everything.
dff = Cd'; % Fdf,Cd, or Sp


%% Start by looking at all neurons plotted on same plot and stacked 
% Colors
co = ...
    [0        0.4470    0.7410;
    0.8500    0.3250    0.0980;
    0.9290    0.6940    0.1250;
    0.4940    0.1840    0.5560;
    0.4660    0.6740    0.1880;
    0.3010    0.7450    0.9330;
    0.6350    0.0780    0.1840];

%% Plot shows all neurons individually plotted on same frame
figure;
plot(xpoints/framerate, dff)
hold on;
plot(xpoints/framerate, binaryPullTimes * max(dff(:)),'b')
title('All Neurons');
if framerate ~= 1
    xlabel('Time (seconds)');
else
    xlabel('Frame');
end
ylabel('DF/F0');
%% Plot shows all neuron plots stacked.
figure;
plot(xpoints/framerate, bsxfun(@plus,dff,0:numNeurons-1))
hold on;
plot(xpoints/framerate, binaryPullTimes * numNeurons,'b')

nvs = gca;
nvs.XTick = 0:50:max(xpoints/framerate);
nvs.YTick = 0:10:numNeurons;
if framerate ~= 1
    xlabel('Time (seconds)');
else
    xlabel('Frame');
end
ylabel('Neuron ID');
title('All Neurons Stacked');
set(gca,'fontsize',24)
set(gca,'LooseInset',get(gca,'TightInset'));

%print -painters -dpng -r600 /Users/Brandon/Documents/Brandon
%Everything/Burke Research ''17/Dr. Hollis
%Lab/717and720/#717_7.11.17/allneurons3D.png
%% Population, Active, Quiescent, Indiscriminant Averages
active = classifications.active;
quiesc = classifications.quiescent;
indisc = classifications.indisc;

figure;
plot(xpoints/framerate, mean(dff,2)+3, 'col', co(1,:)) % Population Average
hold on;
plot(xpoints/framerate, mean(dff(:,active),2)+2, 'col', co(2,:)) % Active Average

plot(xpoints/framerate, mean(dff(:,quiesc),2)+1, 'col', co(3,:)) % Quiescent Average

plot(xpoints/framerate, mean(dff(:,indisc),2), 'col', co(4,:)) % Indiscriminant Active Average

lgd = legend(['Population Average (n=' num2str(length(newNeurons)) ')'], ...
    ['Active Average (n=' num2str(length(active)) ')'], ...
    ['Quiescent Average (n=' num2str(length(quiesc)) ')'], ...
    ['Indiscriminant Average (n=' num2str(length(indisc)) ')']);
% plot(xpoints/framerate, mean(dffActive,2)+2,'color', [0,0,0]+0.8)
% plot(xpoints/framerate, mean(dffActive,2)+2, 'col', co(2,:)) % Active Average

lgd.FontSize = 24;
plot(xpoints/framerate, binaryPullTimes*4,'b') % Pull Bars

set(gca,'YTick',[])
xlabel('Time (seconds)');
set(gca,'fontsize',24)
set(gca,'LooseInset',get(gca,'TightInset'));

%print -painters -dpng -r600 '/Users/Brandon/Documents/Brandon Everything/Burke Research ''17/Dr. Hollis Lab/717and720/#717_7.11.17/neuronClasses3D.png'
%/Users/User/Desktop/717/neuronClasses3D.png

%% Plot Active Neurons + Pull Frame Averages
dffActive=dff(:,active);
figure;
l1 = plot(xpoints/framerate, dffActive, 'color',[0,0,0]+0.8); % Active Neurons in this file
hold on;
l2 = plot(xpoints/framerate, mean(dffActive,2),'g');
hold on;

%plot the averages of the pullframes
for i = 1:length(pulls)
    pull = pulls(i).pullFrames;
    l3 = plot((pull(1)-pTA : pull(2)+pTA)/framerate, pulls(i).average,'r');
    hold on;
end
legend([l1(1) l2(1) l3(1)],'Active Neurons','Mean Average Neuron','Pull Frame Averages');
% plot the pullFrames as vertical bars on the graph
plot(xpoints/framerate, binaryPullTimes * max(max(dffActive)),'b')
xlabel('Time (s)')

%% Individual Neurons averaged to one mouse pull. 
pullTimesMod(1:2:length(pullFrames))=pullFrames(1:2:length(pullFrames)) - pTA;
pullTimesMod(2:2:length(pullFrames))=pullFrames(2:2:length(pullFrames)) + pTA;

pullFrameLength = 225;

neuronPulls = [];
for i = 1:2:length(pullTimesMod)
    addFrames = pullFrameLength - length(pullTimesMod(i):pullTimesMod(i+1));
    neuronPulls = horzcat(neuronPulls, dffActive(pullTimesMod(i):(pullTimesMod(i+1) + addFrames),:));
end

neuronPullsAvg = [];
for i = 1:length(active)
    neuronPullsSize = size(neuronPulls);
    neuronPullsLength = neuronPullsSize(2);
    neuronPullsAvg = horzcat(neuronPullsAvg, mean(neuronPulls(:,i:length(active):neuronPullsLength),2));
end

figure;
xp = (1:pullFrameLength)/framerate;
plot(xp, neuronPullsAvg)
hold on;
frames = pTA / framerate;
plot([frames,frames],[0,2],'b')
plot([(pTA+35)/framerate,(pTA+35)/framerate],[0,2],'b')

%% Total Average in one pull period
figure;
plot(xp, mean(neuronPullsAvg,2),'r')
hold on;
plot([frames,frames],[0,0.4],'b')
plot([(pTA+35)/framerate,(pTA+35)/framerate],[0,0.4],'b')

%% Plot an invidual neuron with pullframe bars - Deconvolved
if ~autoClassifyNeurons
    nnum=1;
    figure('units','normalized','outerposition',[0 0 1 1])
    lineinit = plot(Cd(:,nnum));
    hold on;
    lineinit.Visible = 'Off';
    for nnum = 1:size(Cd,2)
        line = plot(Cd(:,nnum));
        bars = plot(xpoints/framerate, binaryPullTimes * max(Cd(:,nnum)),'b');
        legend(num2str(nnum));
        pause();
        line.Visible = 'Off';
        bars.Visible = 'Off'; 
    end
end