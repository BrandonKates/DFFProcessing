function [ distance ] = vecDistance( coords, vecCoords )
%VECTORIZEDDISTANCECALC Summary of this function goes here
%   Detailed explanation goes here

distance = sqrt(sum(power(repmat(coords,1,length(vecCoords)) - vecCoords,2)));

end

