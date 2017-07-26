function [ neurons, newNeurons ] = indexNeurons( jsonFiles, distThresh )
%JSONPROCESSING Summary of this function goes here
%   Detailed explanation goes here

%% Initialize files
nfiles= length(jsonFiles);

for i = 1:nfiles
    [jsonFiles(i).jmesh(:).nid] = deal([]);
end
%% Match Neurons in each file
neuronIndex = 1;

for i = 1:nfiles
    for j = 1:length(jsonFiles(i).jmesh)
        thisFile = jsonFiles(i).jmesh(j);
        if isempty(thisFile.nid)
            jsonFiles(i).jmesh(j).nid = neuronIndex;
            neuronIndex = neuronIndex + 1;
            for k = 1:nfiles
                if k==i 
                    continue;   
                end
                distance = vecDistance(thisFile.centroid,[jsonFiles(k).jmesh.centroid]);
                sameNeuron = find(distance < distThresh);
                if ~isempty(sameNeuron)
                    [jsonFiles(k).jmesh(sameNeuron).nid] = deal(jsonFiles(i).jmesh(j).nid);
                end
            end
        end
    end
end

neurons = jsonFiles;

%% New Function: attach the neurons with same nid together.

nneurons = neuronIndex-1;

% Setup Struct for Neurons
nfiles= length(jsonFiles);
nframes= length(neurons(1).jmesh(1).dff);
newNeurons = struct('nid', [], 'dff', []);
for i=1:nneurons
    newNeurons(i).nid=i;
end

% Actual Function
for i=1:nneurons
    for j = 1:nfiles
        neuronInd = find(~([neurons(j).jmesh.nid]-i));
        if isempty(neuronInd)
            newNeurons(i).dff = horzcat(newNeurons(i).dff, zeros(nframes,1));   
        else    
            newNeurons(i).dff = horzcat(newNeurons(i).dff, [neurons(j).jmesh(neuronInd).dff]);
        end
    end
end

end
