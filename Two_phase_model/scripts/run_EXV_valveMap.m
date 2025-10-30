%% Valve map mini-sweep  (Phase-2 characterization)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: run_EXV_valveMap.m
% PURPOSE:
%   Perform a mini-sweep (Phase-2 characterization) to generate the valve
%   map: mass flow vs. opening and pressure drop across the EXV.
% OUTPUTS:
%   - /outputs/plots/EXV_valve_map.png
%   - /outputs/logs/valve_map.csv
% NOTES:
%   Compressor speed fixed; u_cmd stepped through test points.
%   Results are steady-state averages suitable for Dymola/Dataset import.
% AUTHOR: Aiden W.  |  Date: <today>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run(fullfile('config','config.m'));
cfg = evalin('base','cfg');

u_sweep = [0.28 0.32 0.34 0.36 0.38 0.40];    % openings to test
results = table([],[],[],[], 'VariableNames', ...
    {'u','A_m2','mdot_kgps','dP_Pa'});  % pre-allocate

for k = 1:numel(u_sweep)
    u_cmd = u_sweep(k);             
    assignin('base','u_cmd',u_cmd);
    % run model for steady-state (~20 s)
    simOut = sim('two_phase_main_loop','StopTime','20');
    logsout = simOut.logsout;
    disp(logsout);

    % extract signals
    md_vec   = logsout.getElement(12).Values.Data;   % md (kg/s)
    Pin_kPa  = logsout.getElement(11).Values.Data;   % upstream (kPa)
    Pout_kPa = logsout.getElement(17).Values.Data;   % downstream (kPa)
    % Last-N averaging
    N = 200;
    n = @(v) min(N,numel(v));
    mdot = mean(md_vec(end-n(md_vec)+1:end));
    Pin  = mean(Pin_kPa(end-n(Pin_kPa)+1:end))  * 1e3;  % Pa
    Pout = mean(Pout_kPa(end-n(Pout_kPa)+1:end)) * 1e3; % Pa

    dP   = Pin - Pout;  
    A_m2 = cfg.exv.Amin_m2 + (cfg.exv.Amax_m2 - cfg.exv.Amin_m2)*sqrt(u_cmd);

    % store
    results = [results; {u_cmd, A_m2, mdot, dP}];
end

% save results
writetable(results, fullfile('outputs','logs','valve_map.csv'));
disp(results);

% quick plot
figure;
yyaxis left
plot(results.u, results.mdot_kgps,'o-','LineWidth',1.4);
ylabel('Mass flow [kg/s]');
yyaxis right
plot(results.u, results.dP_Pa/1e5,'--','LineWidth',1.2);
ylabel('ΔP [bar]');
xlabel('Valve opening u [-]');
title('EXV Valve Characterization – ṁ vs Opening');
grid on;
saveas(gcf, fullfile('outputs','plots','EXV_valve_map.png'));
