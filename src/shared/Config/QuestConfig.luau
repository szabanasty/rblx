--!strict
return table.freeze({
    first_delivery = table.freeze({
        Id = "first_delivery", Name = "Pierwsza dostawa",
        Description = "Odbierz paczkę w hubie i dowieź ją hulajnogą do zielonego punktu.",
        StartLocation = "DeliveryHub", TargetLocation = "DeliveryTarget",
        Money = 80, XP = 30, Reputation = 2, UnlockLevel = 1,
        MinimumRideMeters = 45, MinimumSeconds = 12,
        TimeLimitSeconds = 180, CooldownSeconds = 120,
    }),
})
