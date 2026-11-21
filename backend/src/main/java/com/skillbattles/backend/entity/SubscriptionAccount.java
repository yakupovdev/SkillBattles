package com.skillbattles.backend.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import java.util.UUID;

@Entity @Table(name="subscription_accounts") @Getter @Setter @SQLRestriction("deleted=false")
@SQLDelete(sql="UPDATE subscription_accounts SET deleted=true,updated_at=timezone('UTC',now()) WHERE id=?")
public class SubscriptionAccount extends BaseEntity {
    @Column(nullable=false) private UUID userId;
    @Column(nullable=false) private boolean proActive=true;
    @Column(nullable=false) private int version=1;
}
