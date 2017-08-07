function [ newNeurons, fluorescenceData, classifications, binaryPullTimes,pulls,options] = processDFFInitVars(dir, pullFrames, fr, autoClassifyNeurons, pTA)                                                                                                                                                                                                                                                                                                                                                                                                              
% This function initializes variables needed for processDFFPipeline.m
%   Detailed explanation goes here

    %% Find the json file and Load in variables for dff extraction from same directory.
    if isempty(dir)
        disp('Pick Centroid json file');
        [foldername, dir] = uigetfile('.json', 'Pick Centroid json file');     
        jsonFilePath = fullfile(dir,foldername); % Set the file name using this variable
    else
        jsonFilePath = fullfile(dir, 'centroids.json');
    end

    if(exist(fullfile(dir, 'Fdf.mat'),'file'))
        load(fullfile(dir, 'Fdf.mat'))
    end
    if(exist(fullfile(dir, 'Cd.mat'),'file'))
        load(fullfile(dir, 'Cd.mat'))
    end
    if(exist(fullfile(dir, 'Sp.mat'),'file'))
        load(fullfile(dir, 'Sp.mat'))
    end

    %% Create a new struct with neuron data (nid, dff, Cd, and Sp) concatenated by time (optional)
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
    
    fluorescenceData = struct('Fdf',Fdf_concat,'Cd',Cd_concat,'Sp',Sp_concat);
    
    newNeurons = struct('nid',[],'dff',[],'Cd',[],'Sp',[]);
    neurons = jsonread(jsonFilePath);
    numNeurons = length(neurons.jmesh);
    for i = 1:numNeurons
        newNeurons(i).nid = i;
        newNeurons(i).dff = Fdf_concat(i,:)';
        newNeurons(i).Sp = Sp_concat(i,:)';
        newNeurons(i).Cd = Cd_concat(i,:)';
    end

    %% Initialize Variables
    numFrames = length(Cd_concat);
    xpoints = 1:numFrames;

    if isempty(pTA)
        pTA = 100; % Default Value - frames before and after pull to average
    end
    if isempty(fr)
        fr = 1; %% If no framerate set, just use frame numbers.
    end
    options = struct('numFrames',numFrames,'numNeurons',numNeurons,'pTA',pTA,'xpoints',xpoints,'framerate',fr);
    
    %% Pull Time Data
    if ~isnumeric(pullFrames)
        pullFrames = csvread(pullFrames);
    end
    binaryPullTimes = zeros(1,numFrames);
    for i = 1:2:length(pullFrames)
        binaryPullTimes(pullFrames(i):pullFrames(i+1)) = 1;
    end
    pulls= struct('pullNum',[],'pullFrames',[],'average',[]);
    pullNum = 1;
    for i = 1:2:length(pullFrames)
        thisPull = Cd_concat(:,pullFrames(i) - pTA : pullFrames(i+1) + pTA);
        meanPull = mean(thisPull,1);
        pulls(pullNum).pullNum = pullNum;
        pulls(pullNum).pullFrames = [pullFrames(i) pullFrames(i+1)];
        pulls(pullNum).average = meanPull;
        pullNum = pullNum + 1;
    end
    %% Initialize Data Frame for Classifying Cells as Active or Quiescent Active
    % data(3).im(2).roi_trace_thresh(10,:) % Third Animal on second days 10th roi
    % Data Struct - first input
    data=struct('im',[]);
    data.im = struct('roi_trace_thresh',Sp_concat,'roi_trace_df',Sp_concat);

    % Analysis Struct - second input
    % analysis(3).lever(2).lever_move_frames(:,1) % Third Animal on the Second
    % day - binarized movement frames
    analysis = struct('lever',[]);
    analysis.lever = struct('lever_move_frames',[]);
    analysis(1).lever(1).lever_move_frames = binaryPullTimes';
    
    [classified_rois, classified_p] = AP_classify_movement_cells_continuous(data,analysis); % Seems to work pretty well

    %% Neuron Classification Variables
    if isempty(autoClassifyNeurons)
        autoClassifyNeurons = true;
    end
    if autoClassifyNeurons
        active = find(classified_rois.movement);
        quiesc = find(classified_rois.quiescent);
        indisc = find(classified_rois.unclassified_active);
    else % Have a csv file with the data for
        disp('Pick neuron classification file');
        nCfile = uigetfile(fullfile(dir,'*.csv'),'Pick neuron classification file');
        neuronClass = csvread(fullfile(dir,nCfile));
        active = find(neuronClass==1);
        quiesc = find(neuronClass==2);
        indisc = find(neuronClass==3);
    end
    classifications = struct('classified_rois',classified_rois,'classified_p',classified_p,'active',active,'quiescent',quiesc,'indisc',indisc);
end

