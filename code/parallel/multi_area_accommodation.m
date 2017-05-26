function [out,hist]=multi_area_accommodation(area_in,A)
%% input data
T=area_in(1).T;
TD=area_in(1).TD;
%% decentralized mode
%Global constants and defaults
MAX_ITER = 100;
XTOL     = 1;
YTOL     = 1e-1;
Rho      = 0.001;
alpha    = 1;
%%global variable (exchange infromation)
for a=1:A
    area_in(a).Ftie_val = zeros(T,area_in(a).Ntie);
    area_in(a).lamda    = zeros(T,area_in(a).Ntie);
    deltLam{a}          = ones(T,area_in(a).Ntie);
    resDual{a}          = ones(T,area_in(a).Ntie);
    area_in(a).Rho      = Rho;
end
%ADMM solution
% tic;
parfor a=1:A
    x0(a).Pwind    = area_in(a).Windmax;
    x0(a).Ppv      = area_in(a).PVmax;
    x0(a).Pthermal = zeros(T,area_in(a).Nunit);
    x0(a).onoff    = ones(T,area_in(a).Nunit);
    x0(a).startup  = zeros(T,area_in(a).Nunit);
    x0(a).shutdown = zeros(T,area_in(a).Nunit);
    x0(a).Ftie     = zeros(T,area_in(a).Ntie);
end
for k =1:MAX_ITER
    %%--------------------------- x-update --------------------------------
    parfor a=1:A
        area_out(a)=area_accommodation(area_in(a),x0(a));
        %%---------------------- initial guess ----------------------------
        x0(a).Pwind    = area_out(a).Pwind;
        x0(a).Ppv      = area_out(a).Ppv;
        x0(a).Pthermal = area_out(a).Pthermal;
        x0(a).onoff    = area_out(a).onoff;
        x0(a).startup  = area_out(a).startup;
        x0(a).shutdown = area_out(a).shutdown;
        x0(a).Ftie     = area_in(a).Ftie_val;
    end
%     delete(pool);   
    %%--------------------------- z-update --------------------------------
    for a=1:A
        for b=a+1:A
            for la=1:area_in(a).Ntie
                for lb=1:area_in(b).Ntie
                    if (area_in(a).Tieline(la,1)==b)&&(area_in(b).Tieline(lb,1)==a)
                        resDual{a}(:,la)=-((area_out(a).Ftie(:,la)-area_out(b).Ftie(:,lb))/2-area_in(a).Ftie_val(:,la));
                        resDual{b}(:,lb)=-((area_out(b).Ftie(:,lb)-area_out(a).Ftie(:,la))/2-area_in(b).Ftie_val(:,lb));
                        
                        area_in(a).Ftie_val(:,la)=(area_out(a).Ftie(:,la)-area_out(b).Ftie(:,lb))/2;
                        area_in(b).Ftie_val(:,lb)=(area_out(b).Ftie(:,lb)-area_out(a).Ftie(:,la))/2;                      
                        
                        deltLam{a}(:,la) = Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        deltLam{b}(:,lb) = Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;
                        area_in(a).lamda(:,la) = area_in(a).lamda(:,la)+Rho*(area_out(a).Ftie(:,la)+area_out(b).Ftie(:,lb))/2;
                        area_in(b).lamda(:,lb) = area_in(b).lamda(:,lb)+Rho*(area_out(b).Ftie(:,lb)+area_out(a).Ftie(:,la))/2;                       
                    end
                end
            end
        end
    end
    hist.Xerr(k) =0;
    hist.Yerr(k) =0;
    for a=1:A
       hist.Xerr(k) = max(hist.Xerr(k),max(max(abs(deltLam{a}))));
       hist.Yerr(k) = max(hist.Yerr(k),max(abs(resDual{a}./(area_out(a).Ftie+1))));
    end
    hist.iter=k
    toc;
    if ( hist.Xerr(k)<XTOL )&&( hist.Yerr(k)<YTOL )
        break;
    end
%     Xnorm(k)=0;
%     Znorm(k)=0;
%     LamdaNorm(k)=0;
%     hist.resPnorm(k)=0;
%     hist.resDnorm(k)=0;
%     for a=1:A
%        hist.resPnorm(k) = hist.resPnorm(k)+ sum(sum(deltLam{a}.*deltLam{a}));
%        hist.resDnorm(k) = hist.resDnorm(k)+ sum(sum(resDual{a}.*resDual{a}));
%        Xnorm(k)         = Xnorm(k)+sum(sum(area_out(a).Ftie.*area_out(a).Ftie));
%        Znorm(k)         = Znorm(k)+sum(sum(area_in(a).Ftie_val.*area_in(a).Ftie_val));
%        LamdaNorm(k)     = LamdaNorm(k)+sum(sum(area_in(a).lamda.*area_in(a).lamda));
%     end
%     hist.resPnorm(k)=sqrt(hist.resPnorm(k));
%     hist.resDnorm(k)=sqrt(hist.resDnorm(k));
%     hist.eps_pri(k) = sqrt(a*T)*ABSTOL + RELTOL*max(Xnorm(k), Znorm(k));
%     hist.eps_dual(k)= sqrt(a*T)*ABSTOL + RELTOL*norm(LamdaNorm(k));
%     hist.iter=k;
%     if (hist.resPnorm(k)<hist.eps_pri(k))&&(hist.resDnorm(k)<hist.eps_dual(k))
%         break;
%     end
%     k
%     toc;
end
%% read values of variables
out.area=area_out;