function demo_superheat
% Load config
run(fullfile('config','config.m'));

% Open
mdlPath = fullfile('models','main_loop.slx'); 

% Load the Simulink model
load_system(mdlPath);

% Run
simOut = sim(mdlPath); 

% Extract and plot 
L = simOut.logsout;

if isa(L,'Simulink.SimulationData.Dataset')
    % Dataset path (signal logging)
    P1     = L.getElement('P1').Values;
    P2     = L.getElement('P2').Values;
    SH     = L.getElement('SH').Values;
    T_suct = L.getElement('T_suct').Values;
    mdot   = L.getElement('mdot').Values;
    Opening = L.getElement('Opening').Values;

saveDir = 'D:\Daikin\project\docs\figures';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Superheat Tracking
fig1 = figure('Name','Superheat Tracking','Color','w');
plot(SH.Time, SH.Data,'LineWidth',1.5);
hold on;
yline(7,'--r','SH setpoint','LabelVerticalAlignment','bottom');
xlabel('Time [s]');
ylabel('Superheat [K]');
title('Superheat Tracking');
grid on;
saveas(fig1, fullfile(saveDir,'Superheat_Tracking.png'));

% Valve Opening and Mass Flow
fig2 = figure('Name','Valve and Flow','Color','w');
yyaxis left
plot(Opening.Time,Opening.Data,'b','LineWidth',1.5);
ylabel('Valve Opening [0–1]');
yyaxis right
plot(mdot.Time,mdot.Data,'r','LineWidth',1.5);
ylabel('Mass Flow Rate [kg/s]');
xlabel('Time [s]');
title('Valve Opening and Mass Flow');
grid on;
legend('Opening','ṁ','Location','best');
saveas(fig2, fullfile(saveDir,'Valve_and_Flow.png'));

% Valve Pressure Drop
fig3 = figure('Name','Valve Pressure Drop','Color','w');
plot(P1.Time,(P1.Data - P2.Data)/1e5,'k','LineWidth',1.5);
xlabel('Time [s]');
ylabel('ΔP across valve [bar]');
title('Valve Pressure Drop');
grid on;
saveas(fig3, fullfile(saveDir,'Valve_Pressure_Drop.png'));

% Suction Temperature
fig4 = figure('Name','Suction Temperature','Color','w');
plot(T_suct.Time, T_suct.Data - 273.15,'LineWidth',1.5);
xlabel('Time [s]');
ylabel('T_{suct} [°C]');
title('Evaporator Outlet Temperature');
grid on;
saveas(fig4, fullfile(saveDir,'Suction_Temperature.png'));

end
