
% flip the normal if necessary and determine the orientation flag
manus_orientation_check

%% compute the center point of the object
P_centerRAN = mean(p_best,1) ;
P_centerRAN = P_centerRAN' ; % average of target poinst in base's frame
n_b = n_best' ; % n_best is before modification and n_b will be after modification
Dir_Cam = P_centerRAN-P.baseloc' ; Dir_Cam = Dir_Cam/norm(Dir_Cam); % The vector where points from the camera's location to the object

%% find features of the selected pair of lines
temp = [] ;
for i=1:size(TargetLines,1)
   temp(i) = size(ListPoint_new_shifted{TargetLines(i)},1) ;
end

[~,ind20] = max(temp) ; % select the line with maximum sample number
temp(ind20)=1 ; [~,ind21] = max(temp) ;

TargetPoints2 = ListPoint_new_shifted{TargetLines(ind20)} ; 
set_points2 = [Cloud_B2(TargetPoints2,1)  Cloud_B2(TargetPoints2,2)  Cloud_B2(TargetPoints2,3)];
ind3 = find(isnan(set_points2(:,1))); set_points2(ind3,:)=[];


TargetPoints3 = ListPoint_new_shifted{TargetLines(ind21)} ; 
set_points3 = [Cloud_B2(TargetPoints3,1)  Cloud_B2(TargetPoints3,2)  Cloud_B2(TargetPoints3,3)];
ind3 = find(isnan(set_points3(:,1))); set_points3(ind3,:)=[];

t = 0.005 ; % it was 0.001 before nov 4


[V, L, in11] = ransacfitline(set_points2',t) ; % fit ransac line for a line on the longest edge
lp1 = V(:,1)'  ; lp2 = V(:,2)'  ;  LL1 = [lp1 ; lp2]';
var_v1 = V  ;
var_l1 = L  ;
var_in1 = in11 ; 
var_len1 = length(set_points2) ;

[V, L, in11] = ransacfitline(set_points3',t) ; % fit ransac line for a line on the longest edge
lp1 = V(:,1)'  ; lp2 = V(:,2)'  ;  LL2 = [lp1 ; lp2]';
var_v2 = V  ;
var_l2 = L  ;
var_in2 = in11 ; 
var_len2 = length(set_points3) ;


%%

Dir_XXP1 = (LL1(:,1)-LL1(:,2))/norm(LL1(:,1)-LL1(:,2)) ; % unit vector of the longer line
Dir_XXP2 = (LL2(:,1)-LL2(:,2))/norm(LL2(:,1)-LL2(:,2)) ; % unit vector of the shorter line


%% Detect if the object is thin or not and then assign DirX & DirZ

point_m = mean(LL2,2) ;  % distance between two lines
disL1L2_2d = distance2d(Line_new(ListPair(pair_no,1),:),Line_new(ListPair(pair_no,2),:)) ;
dis_L1L2_3d = norm(cross((point_m-LL1(:,1)),(LL1(:,2)-LL1(:,1))))/norm((LL1(:,2)-LL1(:,1))) ;

% if it's side/inclined grasping and satisfies thin 2d/3d conditions
if (strcmp(flag_orientation,'side')||strcmp(flag_orientation,'inclined'))&& dis_L1L2_3d<P.d_thin3  && disL1L2_2d<P.d_thin2 
    display ('THE OBJECT IS DETECTED AS A THIN OBJECT')
    Dir_XX1 = Dir_XXP1 ;
    Dir_XX2 = Dir_XXP2 ;
    % to find the bisector line of two lines: check if the angle between them
    % is less than 90 degree or more than 90 degree
    if dot(Dir_XX1,Dir_XX2)>0
        Dir_XX = Dir_XX1 + Dir_XX2 ;
    else
        Dir_XX = Dir_XX1 - Dir_XX2 ;
    end
    Dir_XX = Dir_XX/norm(Dir_XX);
    Dir_CamP = Dir_Cam -(dot(Dir_Cam,Dir_XX))*Dir_XX ;
    Dir_CamP = Dir_CamP/norm(Dir_CamP) ;
    Dir_ZZ = Dir_CamP ;
  
else  % the object is not thin
    Dir_ZZ= Dir_ZZ/norm(Dir_ZZ) ; % means forward of end-effector / normal of target surface
    Dir_XX1 = Dir_XXP1-(dot(Dir_ZZ,Dir_XXP1))*Dir_ZZ ; Dir_XX1 = Dir_XX1/norm(Dir_XX1) ;  % projection of X axis on the estimated surface
    Dir_XX2 = Dir_XXP2-(dot(Dir_ZZ,Dir_XXP2))*Dir_ZZ ; Dir_XX2 = Dir_XX2/norm(Dir_XX2) ; % projection of X axis on the estimated surface
    % to find the bisector line of two lines: check if the angle between them
    % is less than 90 degree or more than 90 degree
    if dot(Dir_XX1,Dir_XX2)>0
        Dir_XX = Dir_XX1 + Dir_XX2 ;
    else
        Dir_XX = Dir_XX1 - Dir_XX2 ;
    end
    Dir_XX = Dir_XX/norm(Dir_XX);   
end

%%
Dir_YY = cross(Dir_ZZ, Dir_XX) ; Dir_YY = Dir_YY/norm(Dir_YY) ; 
Dir_vecRAN = [Dir_XX Dir_YY Dir_ZZ] ; % x-axis y-axis z-axis
[regParams,~,~]=absor([1 0 0 ;0 1 0 ;0 0 1 ]',Dir_vecRAN) ;  % convert it to quat.

%%
t_zx = abs(Dir_XX(3)/Dir_XX(1)) ; t_zy = abs(Dir_XX(3)/Dir_XX(2)) ; % fraction of z value wrt x and y of gripper closure direction
if strcmp(flag_orientation,'side') || strcmp(flag_orientation,'inclined')
    if (t_zx<0.2)||(t_zy<0.2)
        display('VERTICAL CLOSURE') % 
        flag_orientation2 = 'side_v' ; 
    elseif (t_zx>5)||(t_zy>5)
        display('HORIZONTAL CLOSURE')
        flag_orientation2 = 'side_h' ;  
    end
end


%%  zc write the position and orientation to txt
% [yaw, pitch, roll] = dcm2angle( Dir_vecRAN);
[yaw, pitch, roll] = dcm2angle( [Dir_ZZ -Dir_YY -Dir_XX ]);
yaw = yaw/pi*180;
if abs(yaw)>90
    yaw = yaw+180;
end


% yaw ;
% pitch = pitch/pi*180 ;
% 
% % roll = roll/pi*180
% roll = 180;
% fid=fopen('C:\\MANUS\\CommonSpace\\new_vision\\pos_ypr.txt','w');
% fprintf(fid, '%f  \n', [1000*P_centerRAN' yaw pitch roll]);
% fclose(fid);
% 
% fid2=fopen('C:\\MANUS\\CommonSpace\\new_vision\\visionflag.txt','w');
% fprintf(fid2, '%f  \n', 1);
% fclose(fid2);


%%

