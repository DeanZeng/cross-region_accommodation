%%calculate the up/down reserve
Endh=72;
A=2;
ResUp=cell(1,2);
ResDn=cell(1,2);
for a=1:A
    for t=1:Endh
            ResUp{a} (t)=sum(onoff_F{a}(t,:).*in_full.area(a).Pmax)+in_full.area(a).Windmax(t)+in_full.area(a).PVmax(t)...
                +sum(in_full.area(a).Tieline(:,3))-(in_full.area(a).Demand(t)+in_full.area(a).ReserveUp(t));
            ResDn{a}(t)=(sum(onoff_F{a}(t,:).*in_full.area(a).Pmin)-sum(in_full.area(a).Tieline(:,3))...
                -(in_full.area(a).Demand(t)-in_full.area(a).ReserveDn(t)));
    end
end
figure;
hold on;
for a=1:A
    stairs(ResUp{a},'');
end
title('up reserve');
legend('area 1','area 2');

hold off;
figure;
hold on;
for a=1:A
    stairs(ResDn{a});
end
title('dowm reserve');
legend('area 1','area 2');
hold off;