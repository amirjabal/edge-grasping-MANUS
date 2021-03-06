function [pcloud, distance] = depthToCloud_v2(depth,constant , topleft, center)

% 09032015 modified for new kinect


% Input: 
% depth - the depth image
% topleft - the position of the top-left corner of depth in the original depth image. Assumes depth is uncropped if this is not provided
%
% Output:
% pcloud - the point cloud, where each channel is the x, y, and z euclidean coordinates respectively. Missing values are NaN.
% distance - euclidean distance from the sensor to each point
%

if nargin < 2
    topleft = [1 1];
end

depth= double(depth);
depth(depth == 0) = nan;


% RGB-D camera constants
[imh, imw] = size(depth);
%center = [imw/2 imh/2];

MM_PER_M = 1000;

% convert depth image to 3d point clouds
pcloud = zeros(imh,imw,3);
xgrid = ones(imh,1)*(1:1:imw) + (topleft(1)-1) - center(1);
ygrid = (1:1:imh)'*ones(1,imw) + (topleft(2)-1) - center(2);

pcloud(:,:,1) = depth/MM_PER_M;
pcloud(:,:,2) = xgrid.*depth/constant/MM_PER_M;
pcloud(:,:,3) = ygrid.*depth/constant/MM_PER_M;

distance = sqrt(sum(pcloud.^2,3));

