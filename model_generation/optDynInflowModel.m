%% Prepare basic aerodynamic data
% load('aerodata.mat')
fst_file= '../example_data/sim/coh_URef-4_maininput.fst';
LAM= 3:0.5:13;
TH= 0:0.5:22;

data= loadAeroData(fst_file);
data.LAM= LAM;
data.TH= TH;

outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};
aerofields= aerodynAeroQSField(LAM, TH, fst_file, outputs);
CP1= aerofields.RtAeroCp;
save('aerodata', 'data', 'aerofields')

%% Prepare dynamic inflow step data
% load('allStepsFromNeighbours.mat')
% step height 
dlam= 1; % 0.1; 
dth= 1; % 0.2;
mask= CP1>-0.1;
[TT, V1, CP01, CP0, LAM0, TH0, V0, sTT]= allStepsFromNeighboursAD(fst_file, LAM, TH, dlam, dth, mask);
A1= mean(aerofields.AxInd, 3);
save('allStepsFromNeighbours', 'A1', 'TT', 'CP1', 'V1', 'CP01', 'CP0', 'LAM0', 'TH0', 'V0', 'LAM', 'TH', 'sTT')

%% Tuning parameters: weihgts for the cost function terms
w_fit= 1;              % weight for measurement fitting
w_smooth_cp= 0.01;     % weight for smoothing dcp parameters
w_smooth_a= 0.01;      % weight for smoothing a parameters
w_fix_a= 1e-4;         % weight for anchoring a parameters 
w_fix_neg_cp= 1e-4;    % weight for fitting dcp when cp is negative

%% prepare the interpolation matrices and parameter vectors
j_SEL= zeros(numel(CP1)*numel(CP01{1}), 1);
j_SEL_neg_cp= zeros(numel(CP1), 1);
s_MEAN= zeros(4, numel(CP1)*numel(CP01{1}));

j_INT= zeros(4, numel(CP1)*numel(CP01{1}));
s_INT= zeros(4, numel(CP1)*numel(CP01{1}));

VV0= zeros(numel(CP1)*numel(CP01{1}), 1);       % wind speeds before step
VV1= zeros(numel(CP1)*numel(CP01{1}), 1);       % wind speeds after step
DYN_CP= zeros(numel(CP1)*numel(CP01{1}), 1);    % dynamic cp after step
LLAM0= zeros(numel(CP1)*numel(CP01{1}), 1);     % TSR before step
TTH0= zeros(numel(CP1)*numel(CP01{1}), 1);      % pitch angle before step

i_e= 0;
i_neg_cp= 0;
for i_lam= 1:size(CP1, 1)
    for i_th= 1:size(CP1, 2)
        i_a= sub2ind(size(CP01), i_lam, i_th);

        if ~mask(i_lam, i_th)
            j_SEL_neg_cp(i_neg_cp+1)= i_a;
            i_neg_cp= i_neg_cp+1;
            
            continue
        end
        
        cp01= CP01{i_lam, i_th};
        lam0= LAM0{i_lam, i_th};
        th0= TH0{i_lam, i_th};
        vv0= V0{i_lam, i_th};
        
        idx= lam0>=min(LAM) & lam0<=max(LAM) & th0>=min(TH) & th0<=max(TH);
        cp01= cp01(idx); 
        lam0= lam0(idx); 
        th0= th0(idx);
        vv0= vv0(idx);
        
        for i_0= 1:length(cp01)
            lam0_idx= find(lam0(i_0)>=LAM(1:end-1), 1, 'last');
            th0_idx= find(th0(i_0)>=TH(1:end-1), 1, 'last');
            
            j_INT(1, i_0 + i_e)= sub2ind(size(CP01), lam0_idx, th0_idx);
            j_INT(2, i_0 + i_e)= sub2ind(size(CP01), lam0_idx+1, th0_idx);
            j_INT(3, i_0 + i_e)= sub2ind(size(CP01), lam0_idx, th0_idx+1);
            j_INT(4, i_0 + i_e)= sub2ind(size(CP01), lam0_idx+1, th0_idx+1);
            
            lam0_fact1= (lam0(i_0)-LAM(lam0_idx))/(LAM(lam0_idx+1)-LAM(lam0_idx));
            lam0_fact0= 1-lam0_fact1;
            th0_fact1= (th0(i_0)-TH(th0_idx))/(TH(th0_idx+1)-TH(th0_idx));
            th0_fact0= 1-th0_fact1;
            
            s_INT(1, i_0 + i_e)= lam0_fact0*th0_fact0;
            s_INT(2, i_0 + i_e)= lam0_fact1*th0_fact0;
            s_INT(3, i_0 + i_e)= lam0_fact0*th0_fact1;
            s_INT(4, i_0 + i_e)= lam0_fact1*th0_fact1;  
        end
        
        j_SEL((1:length(cp01)) + i_e)= i_a;
        s_MEAN((1:length(cp01)) + i_e)= 1/length(cp01);
        VV0((1:length(cp01)) + i_e)= vv0;
        VV1((1:length(cp01)) + i_e)= V1(i_lam, i_th);
        DYN_CP((1:length(cp01)) + i_e)= cp01-CP1(i_lam, i_th);
        LLAM0((1:length(cp01)) + i_e)= lam0;
        TTH0((1:length(cp01)) + i_e)= th0;
        
        i_e= i_e + length(cp01);
    end
end

SEL= sparse(1:i_e, j_SEL(1:i_e), ones(1, i_e), i_e, numel(CP01));       % selection matrix mapping break point parameters to measurement
INT= sparse(repmat(1:i_e, 4, 1), j_INT(:, 1:i_e), s_INT(:, 1:i_e), i_e, numel(CP01));     % interpolation matrix mapping break point parameters to measurement
MEAN= sparse(1:i_e, j_SEL(1:i_e), s_MEAN(1:i_e), i_e, numel(CP01));                       % matrix for calculating the average of all measurements corresponding to one break point
SEL_neg_cp= sparse(1:i_neg_cp, j_SEL_neg_cp(1:i_neg_cp), ones(1, i_neg_cp), i_neg_cp, numel(CP01)); % selection matrix for break point parameters where cp is negative

VV0= VV0(1:i_e);        % wind speed at step origin
VV1= VV1(1:i_e);        % wind speed at step target
DYN_CP= DYN_CP(1:i_e);  % dynamic cp value offest after step 
LLAM0= LLAM0(1:i_e);    % TST before step
TTH0= TTH0(1:i_e);      % pitch angle before step

%% setup the cost function terms
dcp_da= optimvar('dcp_da', size(CP01));
a= optimvar('a', size(CP01));

% values for calculating the estimated dynamic cp form parameters
DCP_DA= SEL*reshape(dcp_da, [], 1); % fictitious partial derivative of cp wrt. rotor average axial induction factor
AA0= INT*reshape(a, [], 1);         % fictitious axial induction factor before step
AA1= SEL*reshape(a, [], 1);         % fictitious axial induction factor after step

% approximation of dynamic cp value offest after step 
% linear variant
% DYN_CP_HAT= DCP_DA .* (VV0./VV1.*AA0 - AA1); 

% non-linear variant
AA_DYN= VV0./VV1.*AA0;  % approximation of fictitious axial induction factor after step
DYN_CP_HAT= DCP_DA .* ((1-AA_DYN).^2 - (1-AA1).^2);

% the fitting error
e_fit= DYN_CP_HAT-DYN_CP;

% smoothness "error" for dcp parameters: the second derivative in both dimensions
e_smooth_cp= [reshape(diff(dcp_da, 3), 1, []) reshape(diff(dcp_da, 3, 2), 1, [])];

% smoothness "error" for a parameters: the second derivative in both dimensions
e_smooth_a= [reshape(diff(a, 3), 1, []) reshape(diff(a, 3, 2), 1, [])];

% "error" for anchoring a parameters: difference between a parameters and
% anchor values
e_fix_a= reshape(a-A1, 1, []);

% "error" for fitting dcp when cp is negative: dcp shall be 0 there
e_fix_neg_cp= SEL_neg_cp*reshape(dcp_da, [], 1);

% the cost function terms
f_fit= sum(e_fit.^2);               % term for measurement fitting
f_smooth_cp= sum(e_smooth_cp.^2);   % term for smoothing dcp parameters
f_smooth_a= sum(e_smooth_a.^2);     % term for smoothing a parameters
f_fix_a= sum(e_fix_a.^2);           % term for anchoring a parameters 
f_fix_neg_cp= sum(e_fix_neg_cp.^2); % term for fitting dcp when cp is negative

%% setup the optimization problem
optprob= optimproblem;

% the cost function is the weighted sum of all terms
optprob.Objective= w_fit*f_fit + w_smooth_cp*f_smooth_cp + w_smooth_a*f_smooth_a + w_fix_a*f_fix_a + w_fix_neg_cp*f_fix_neg_cp;

% initial values
x0.dcp_da= zeros(size(CP01));
x0.a= A1;

% solve the problem
sol= optprob.solve(x0, 'Options', optimoptions('lsqnonlin', 'Display','iter'));

%% calculate the mean fitting error
e_fit_sol= evaluate(e_fit, sol)./max(0.0025, abs(DYN_CP));
EE= reshape(MEAN'*abs(e_fit_sol), size(CP1));
EE(CP1<0)= nan;
surf(LAM, TH, EE')

%% Smooth the field of scaled time constants
% the field to smooth
tt= optimvar('tt', size(TT));

% weights for fitting and smoothing
w_fit= 1;
w_smooth_tt= 1;

% sanitizing the time constants. (there should be a more elegant solution
% to this: why are there such deviant results?)
TT(TT>60)= nan;
TT(TT<30)= nan;

%% the fitting error and the smoothness "error"
TT_flat= reshape(TT, [], 1);
tt_flat= reshape(tt, [], 1);
e_fit= tt_flat(~isnan(TT_flat)) - TT_flat(~isnan(TT_flat));
e_smooth_tt= [reshape(diff(tt, 3), 1, []) reshape(diff(tt, 3, 2), 1, [])];

f_fit= sum(e_fit.^2);
f_smooth_tt= sum(e_smooth_tt.^2);

%% solve the smoothing problem
optprob= optimproblem;
optprob.Objective= w_fit*f_fit + w_smooth_tt*f_smooth_tt;

x0.tt= ones(size(TT))*60;

sol_tt= optprob.solve(x0, 'Options', optimoptions('lsqlin', 'Display','iter'));

%% save result
save('sol_dyn_cp', 'sol', 'sol_tt')
