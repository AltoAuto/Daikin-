%% Project startup (auto-runs when the .prj opens)
% config/config.m

clc;  fprintf('Loading Valve Test System\n');

% Load project path
projRoot = fileparts(mfilename('fullpath')); 
projRoot = fileparts(projRoot);
addpath(fullfile(projRoot,'models'));
addpath(fullfile(projRoot,'scripts'));
addpath(fullfile(projRoot,'lib'));
addpath(fullfile(projRoot,'lib','blocks'));

% checks docs and figure
figDir = fullfile(projRoot,'docs','figures');
if ~exist(figDir,'dir'), mkdir(figDir); end

% set global varible
CFG = struct();
CFG.t_stop   = 60;          % [s] total simulation times 
CFG.dt_local = 1e-3;        % Simscape local solver sample time

% Source (compressor surrogate)
CFG.P_high = 9e5;        %  [Pa] high pressure reservior
CFG.P_low = 4e5;          %  [Pa] low pressure reservior
CFG.high_reservior_tep = 306;   % 33.5 [C] high pressure side tempreture 
CFG.low_reservior_tep = 306;    % 33.5 [C] low pressure side tempreture 


%% Valve model
cfg.mode =0;     % Valve selection mode: 1 PI contorl, 0 Manual sweep
cfg.exv.mode               = "area_sqrt";    % "area_sqrt" | "area_table" | "cv_table"

%  Actuator & limits 
cfg.exv.u_min              = 0.05;           % [-] min commanded opening
cfg.exv.u_max              = 0.95;           % [-] max commanded opening
cfg.exv.rate_lim_per_s     = 0.03;           % [1/s] max opening slew
cfg.exv.tau_s              = 0.10;           % [s] first-order actuator lag

% EXV area mapping (sqrt-law approximation)
% A(u) = Amin + (Amax – Amin)*sqrt(u)
% Approximates real valve flow behavior (ṁ ∝ A*sqrt(ΔP)); replace with
% measured Cv/area data when available.
cfg.exv.Amax_m2           = 2.4e-6;                  % [m²] fully open effective flow area
cfg.exv.Amin_m2           = 0.05*cfg.exv.Amax_m2;    % [m²] leakage / never zero
cfg.exv.area_map_u_vec    = [0 1];                   % [-] opening command breakpoints
cfg.exv.area_map_A_m2_vec = [cfg.exv.Amin_m2 cfg.exv.Amax_m2];  % [m²] placeholder map

% Demo step (open-loop test) 
cfg.exv.step_u1            = 0.33;           % [-] initial opening
cfg.exv.step_u2           = 0.37;           % [-] final opening
cfg.exv.step_time_s        = 20;             % [s] step time

% Condenser Pipe (TL)
CFG.T_amb_condK = 293;   % 33 °C (typical ambient; condenser dumps heat OUT)
CFG.pipe.L_cond = 2;        % [m] length of the pipe
CFG.pipe.D_cond = 0.02;    % [m] diameter of the pipe

% Evaporator Pipe (TL)
CFG.t_step   = 20;          % [s] time of step
CFG.T_amb_evapK = 320;   % 47 °C (forces heat INTO evaporator)
CFG.pipe.L_evap = 1;         % [m] length of the pipe
CFG.pipe.D_evap = 0.012;    % [m] diameter of the pipe

% Up stream and down stream short pipe parameter 
CFG.P_init_up      = 6.5e5;     % [Pa] initial pressure in upstream short pipe/chamber
CFG.P_init_dn      = 6.0e5;     % [Pa] initial pressure in downstream short pipe/chamber
CFG.cushion_up.L   = 0.10;      % [m] upstream short pipe length
CFG.cushion_up.D   = 0.010;     % [m]
CFG.cushion_dn.L   = 0.10;      % [m] downstream short pipe length
CFG.cushion_dn.D   = 0.010;     % [m]

% Superheat control
CFG.SH_refK  = 7.0;         % [K] desired superheat setpoint
CFG.PI       = struct('Kp',0.40,'Ki',0.10,'Kd',0.0,'UseAW',true); %PID control, proportional gain, integral, derivative 

% Heat transfer parameter
CFG.h_cond = 10;  % [W/(m^2*K)] 
CFG.h_evap = 10;  % [W/(m^2*K)] 

% Thermal liquid setting
CFG.MinValidP      = 1e5;       % [Pa] Thermal Liquid Settings → Minimum valid pressure
CFG.useElevation   = false;     % turn OFF elevation effects while debugging

% short pipe setting 
CFG.P_init_up      = 6.5e5;     % [Pa] initial pressure in upstream short pipe/chamber
CFG.P_init_dn      = 6.0e5;     % [Pa] initial pressure in downstream short pipe/chamber

% Super Heat = Tsuction - Ts at(Psuction)
% Note: this is only for approximation, it act as a placeholder 
Pvec_kPa = [300 400 500 600 700 800 900 1000];             % Vector of suction pressrures
Tvec_K   = [258 265 271 277 282 287 291 295];              % ~ -15 to +22°C

% assign to base workspace
assignin('base','CFG',CFG);
assignin('base','Pvec_kPa',Pvec_kPa);
assignin('base','Tvec_K',Tvec_K);
assignin('base','FIG_DIR',figDir);

% Buslog
if ~evalin('base','exist(''BusLogs'',''var'')') 
    BusLogs = Simulink.Bus;
    names = {'P1','P2','T_suct','P_suct','mdot','Opening','SH'};
    for i=1:numel(names)
        el = Simulink.BusElement;
        el.Name = names{i};
        el.DataType = 'double';
        el.Dimensions = 1;
        el.SampleTime = -1;
        el.Complexity = 'real';
        BusLogs.Elements(end+1) = el;
    end
    assignin('base','BusLogs',BusLogs);
end

fprintf('CFG loaded. Figures %s\n', figDir);
