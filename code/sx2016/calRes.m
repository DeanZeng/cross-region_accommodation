%%calculate the up/down reserve
ResUp=cell(1,2);
ResDn=cell(1,2);
for a=1:2
    for t=1:168
            ResUp{a} (t)=sum(onoff_F{a}(t,:).*Pmax{a})+Windmax(t,a)+PVmax(t,a)...
                +sum(Tieline{a}(:,3))-(Demand(t,a)+ReserveUp(t,a));
            ResDn{a}(t)=(sum(onoff_F{a}(t,:).*Pmin{a})-sum(Tieline{a}(:,3))...
                -(Demand(t,a)-ReserveDn(t,a)));
    end
end