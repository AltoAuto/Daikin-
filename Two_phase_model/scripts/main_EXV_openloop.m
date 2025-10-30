%% main_EXV_openloop.m  —  Phase-2 demo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: main_EXV_openloop.m
% PURPOSE:
%   Demonstrate dynamic EXV opening step (open-loop) and corresponding
%   superheat (SH) response in the two-phase refrigerant loop.
% OUTPUTS:
%   - /outputs/plots/EXV_SH_vs_Opening.png
%   - /outputs/logs/exv_openloop.mat, .csv
% AUTHOR: Aiden W.  |  Date: <today>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run(fullfile('config','config.m'));
logsout = sim('two_phase_main_loop').logsout;       % run model

% Plot & save core results
t = logsout.getElement('SH').Values.Time;
SH = logsout.getElement('SH').Values.Data;
u  = logsout.getElement('A_m2').Values.Data;

figure;
yyaxis left;  plot(t,SH,'LineWidth',1.5); ylabel('Superheat [K]');
yyaxis right; plot(t,u,'--','LineWidth',1.2); ylabel('Valve Opening [m^2]');
xlabel('Time [s]'); grid on;
title('EXV Opening Sweep – Superheat Response');
saveas(gcf,'outputs/plots/EXV_SH_vs_Opening.png');
