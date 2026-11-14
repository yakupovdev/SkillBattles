package com.skillbattles.backend.entity;
import com.skillbattles.backend.dto.CheckoutIntentDto;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.SQLRestriction;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.type.SqlTypes;
import java.time.Instant;
import java.util.*;
@Entity @Table(name="subscription_accounts") @Getter @Setter @SQLRestriction("deleted=false")
@SQLDelete(sql="UPDATE subscription_accounts SET deleted=true,updated_at=timezone('UTC',now()) WHERE id=?")
public class SubscriptionAccount extends BaseEntity {
    @Column(nullable=false) private UUID userId;
    private String customerId;
    private String subscriptionId;
    @Column(nullable=false) private String planCode="FREE";
    @Column(nullable=false) private String status="NONE";
    private Instant currentPeriodStart;
    private Instant currentPeriodEnd;
    @Column(nullable=false) private boolean cancelAtPeriodEnd;
    @Column(nullable=false) private boolean paid;
    @Column(nullable=false) private boolean proActive;
    @Column(nullable=false) private int version=1;
    @JdbcTypeCode(SqlTypes.JSON) @Column(nullable=false,columnDefinition="jsonb") private Map<UUID,CheckoutIntentDto> checkouts=new HashMap<>();
    @ElementCollection @CollectionTable(name="stripe_event_receipts",joinColumns=@JoinColumn(name="account_id"))
    @Column(name="event_id",nullable=false) private Set<String> events=new HashSet<>();
}
