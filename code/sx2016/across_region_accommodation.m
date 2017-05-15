function out=across_region_accommodation(in)
%% input data
%%-------------------------- system data ----------------------------------
A=in.A;
T=in.T;
TD=in.TD;                      %% number of days
%%---------------------------- area data ----------------------------------
Nunit = in.Nunit;              %% number of units
Ntie  = in.Ntie;               %% number of tie lines
%%------------------------ initialization ---------------------------------
Pmax=in.Pmax;                  %% unit maximum output
Pmin=in.Pmin;                  %% unit minimum output
Rampup=in.Rampup;               %% unit ramping up rates
Rampdown=in.Rampdown;          %% unit ramping down rates
Minup=in.Minup;                %% unit minimun up time
Mindown=in.Mindown;            %% unit minimum dowm time
Onoff_t0=in.Onoff_t0;          %% initial status at t=0
Pthermal_t0=in.Pthermal_t0;    %% initial output at t=0
On_t0=in.On_t0;                %% length of time unit g has to be on at the beginning
Off_t0=in.Off_t0;              %% length of time unit g has to be off at the beginning
Demand=in.Demand;              %% demand
Windmax= in.Windmax;           %% theory output of wind power
PVmax  = in.PVmax;             %% theory output of PV
Tieline= in.Tieline;           %% tie lines
Ftie0=   in.Ftie0;             %% fixed power flow
Etie =   in.Etie;              %% exchage energy each day
TDstart= in.TDstart;
%% variables
%%--------------------------- wind power & PV -----------------------------
Pwind=sdpvar(T,A,'full');    %% output of wind power 
Ppv  =sdpvar(T,A,'full');    %% output of PV 

%%--------------------------- thermal unit --------------------------------
Pthermal=cell(1,A);          %% output of thermal unit
onoff=cell(1,A);           %% on_off status;
startup=cell(1,A);              %% start up indicator
shutdown=cell(1,A);            %% shut down indicator
for a=1:A
    Pthermal{a} = sdpvar(T,Nunit(a),'full');
    onoff{a}    = binvar(T,Nunit(a),'full');
    startup{a}  = binvar(T,Nunit(a),'full');
    shutdown{a} = binvar(T,Nunit(a),'full');
end
%%---------------------------- tie lines ----------------------------------
Ftie=cell(1,A);
for a=1:A
    Ftie{a} = sdpvar(T,Ntie(a),'full');
end
%% constraints
Constraints=cell(1,A);
for a=1:A
    %--------------------- thermal unit constraints ------------------------
    % binary variable logic
    Constraints{a}=[Constraints{a},(startup{a}-shutdown{a}==onoff{a}-[Onoff_t0{a};onoff{a}(1:T-1,:)]):'logical_1'];
    Constraints{a}=[Constraints{a},(startup{a}+shutdown{a}<=ones(T,Nunit(a))):'logical_2'];
    % output limit
    for t = 1:T
       Constraints{a} = [Constraints{a}, (onoff{a}(t,:).*Pmin{a} <=...
           Pthermal{a}(t,:) <= onoff{a}(t,:).*Pmax{a}):'output limit'];
    end
%     for t = 1:T
%        Constraints{a} = [Constraints{a}, (Pmin{a} <=...
%            Pthermal{a}(t,:) <= Pmax{a}):'output limit'];
%     end
    % minimum up/down time
    Lini=On_t0{a}+Off_t0{a};
    for t=1:Lini
        onoff{a}(t,:)=Onoff_t0{a};
    end
    for t = Lini+1:T
        for unit = 1:Nunit(a)
            tt=max(1,t-Minup{a}(unit)+1);
            Constraints{a} = [Constraints{a}, (sum(startup{a}(tt:t,unit))...
                <= onoff{a}(t,unit)):'min_up'];
            tt=max(1,t-Mindown{a}(unit)+1);
            Constraints{a} = [Constraints{a}, (sum(shutdown{a}(tt:t,unit))...
                <= 1-onoff{a}(t,unit)):'min_down'];
        end
    end
    % ramping up/down limit
    Constraints{a}=[Constraints{a},(-Rampdown{a} <= Pthermal{a}(1,:)-Pthermal_t0{a}...
            <= Rampup{a}):'ramp0'];
    for t=2:T
        Constraints{a}=[Constraints{a},(-Rampdown{a} <= Pthermal{a}(t,:)-Pthermal{a}(t-1,:)...
            <= Rampup{a}):'ramp'];
    end
    
    %------------------------------- wind power & PV ----------------------
    Constraints{a}=[Constraints{a},(zeros(T,1) <= Pwind(:,a) <= Windmax(:,a)):'wind power output limit'];
    Constraints{a}=[Constraints{a},(zeros(T,1) <= Ppv(:,a)   <= PVmax(:,a)):'wind power output limit'];
    
    %------------------------------- Tie-line -----------------------------
    for line=1:Ntie(a)
        if Tieline{a}(line,2)==1
            Constraints{a}=[Constraints{a},(Ftie{a}(:,line)==Ftie0{a}(:,line)):'tie typeI'];
        elseif Tieline{a}(line,2)==2
            for t=1:T
                Constraints{a}=[Constraints{a},(-Tieline{a}(line,3)<=...
                    Ftie{a}(t,line)<=Tieline{a}(line,3)):'tie typeII'];
            end
        elseif Tieline{a}(line,2)==3
            for t=1:T
                Constraints{a}=[Constraints{a},(-Tieline{a}(line,3)<=...
                    Ftie{a}(t,line)<=Tieline{a}(line,3)):'tie typeIII 1'];
            end
            for td=1:TD
               Constraints{a}=[Constraints{a},(sum(Ftie{a}(TDstart(td):TDstart(td+1),line))...
                   ==Etie{a}(td,line)):'tie typeIII 2'];
            end
        end
    end
    %------------------------------- power balance ------------------------
    for t=1:T
        Constraints{a}=[Constraints{a},(sum(Pthermal{a}(t,:))+Pwind(t,a)+Ppv(t,a)...
            ==Demand(t,a)+sum(Ftie{a}(t,:))):'power balance'];
    end
    %------------------------------- spinning reserve ---------------------
%     for t=1:T
%         Constraints{a}=[Constraints{a},(sum(onoff{a}(t,:).*Pmax{a})+Windmax(t,a)+PVmax(t,a)...
%             +sum(Tieline{a}(:,3))>=Demand(t,a)+ReserveUp(t,a)):'up reserve'];
%         Constraints{a}=[Constraints{a},(sum(onoff{a}(t,:).*Pmin{a})-sum(Tieline{a}(:,3))...
%             <=Demand(t,a)-ReserveDn(t,a)):'down reserve'];
%     end
end
%%--------------------------- consensus -----------------------------------
% Con_global=[];
% for a=1:A
%     Con_global =[Con_global,Constraints{a}];
% end
% for a=1:A
%     for b=a+1:A
%         for la=1:Ntie(a)
%             for lb=1:Ntie(b)
%                 if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
%                     Con_global =[Con_global,(Ftie{a}(:,la)+Ftie{b}(:,lb)==0):'consensus'];                
%                 end
%             end
%         end
%     end
% end

%% centrialized mode 
% %%--------------------------- Objective -----------------------------------
% maxObj=sum(sum(Pwind))+sum(sum(Ppv));  
% 
% %%--------------------------- solution ------------------------------------
% options=sdpsettings('solver','gurobi');
% optimize(Con_global,-maxObj,options);

%% decentralized mode
%Global constants and defaults
QUIET    = 0;
MAX_ITER = 20;
ABSTOL   = 1e-2;
RELTOL   = 1e-2;
Rho      = 0.1;
alpha    = 1;
%%global variable (exchange infromation)
lamda=cell(1,A);
deltLam=cell(1,A);
resDual=cell(1,A);
Ftie_val=cell(1,A);
for a=1:A
    Ftie_val{a} = zeros(T,Ntie(a));
    lamda{a} = zeros(T,Ntie(a));
    deltLam{a}= ones(T,Ntie(a));
    resDual{a}= ones(T,Ntie(a));
end
%ADMM solution
% tic;
for k =1:MAX_ITER
    %%--------------------------- x-update --------------------------------
    %%Objective
    minLang=cell(1,A);
    for a=1:A
        %%Objective
        minLang{a}= -sum(Pwind(:,a))-sum(Ppv(:,a));
        for b=1:A
            for la=1:Ntie(a)
                for lb=1:Ntie(b)
                    if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                        minLang{a} = minLang{a} +...
                            lamda{a}(:,la)'*(Ftie{a}(:,la)+Ftie_val{b}(:,lb))+...
                            Rho/2*(Ftie{a}(:,la)+Ftie_val{b}(:,lb))'*(Ftie{a}(:,la)+Ftie_val{b}(:,lb));                
                    end
                end
            end
        end
        %%solver
        Ops = sdpsettings('solver','gurobi','usex0',1,'showprogress',0);
        optimize(Constraints{a},minLang{a},Ops);  
    end
    %%--------------------------- z-update --------------------------------
    for a=1:A
        for b=a+1:A
            for la=1:Ntie(a)
                for lb=1:Ntie(b)
                    if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                        resDual{a}(:,la)=-Rho*((value(Ftie{a}(:,la))-value(Ftie{b}(:,lb)))/2-Ftie_val{a}(:,la));
                        resDual{b}(:,lb)=-Rho*((value(Ftie{b}(:,lb))-value(Ftie{a}(:,la)))/2-Ftie_val{b}(:,lb));
                        
                        Ftie_val{a}(:,la)=(value(Ftie{a}(:,la))-value(Ftie{b}(:,lb)))/2;
                        Ftie_val{b}(:,lb)=(value(Ftie{b}(:,lb))-value(Ftie{a}(:,la)))/2;                      
                        
                        deltLam{a}(:,la)=Rho*(value(Ftie{a}(:,la))+value(Ftie{b}(:,lb)))/2;
                        deltLam{b}(:,lb)=Rho*(value(Ftie{b}(:,lb))+value(Ftie{a}(:,la)))/2;
                        lamda{a}(:,la) = lamda{a}(:,la)+Rho*(value(Ftie{a}(:,la))+value(Ftie{b}(:,lb)))/2;
                        lamda{b}(:,lb) = lamda{b}(:,lb)+Rho*(value(Ftie{b}(:,lb))+value(Ftie{a}(:,la)))/2;                       
                    end
                end
            end
        end
    end
    resPnorm(k)=0;
    resDnorm(k)=0;
    for a=1:A
       resPnorm(k)= resPnorm(k)*resPnorm(k)+ sum(sum(deltLam{a}.*deltLam{a}));
       resDnorm(k)= resDnorm(k)*resDnorm(k)+ sum(sum(resDual{a}.*resDual{a}));
    end
    resPnorm(k)=sqrt(resPnorm(k));
    resDnorm(k)=sqrt(resDnorm(k));
    if (resPnorm(k)<ABSTOL)&&(resDnorm(k)<ABSTOL)
        break;
    end
%     k
%     toc;
end
%% read values of variables
%%--------------------------- wind power & PV -----------------------------
Pwind_V=value(Pwind);    %% output of wind power 
Ppv_V  =value(Ppv);      %% output of PV 

%%--------------------------- thermal unit --------------------------------
Pthermal_V=cell(1,A);          %% output of thermal unit
onoff_V=cell(1,A);           %% on_off status;
startup_V=cell(1,A);              %% start up indicator
shutdown_V=cell(1,A);            %% shut down indicator
for a=1:A
    Pthermal_V{a} = value(Pthermal{a});
    onoff_V{a}=value(onoff{a});
    startup_V{a}  = value(startup{a});
    shutdown_V{a} = value( shutdown{a});
end

%%---------------------------- tie lines ----------------------------------
Ftie_V=cell(1,A);
for a=1:A
    Ftie_V{a} = value( Ftie{a});
end

minLang_V=cell(1,A);
for a=1:A
    minLang_V{a}=value(minLang{a});
end
out.Pwind    = Pwind_V;
out.Ppv      = Ppv_V;
out.Pthermal = Pthermal_V;
out.onoff    = onoff_V;
out.startup  = startup_V;             
out.shutdown = shutdown_V;            
out.Ftie     = Ftie_V;