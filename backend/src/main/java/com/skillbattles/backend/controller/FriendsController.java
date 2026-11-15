package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.mapper.FriendMapper;
import com.skillbattles.backend.processor.*;
import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.validation.annotation.Validated;
import io.swagger.v3.oas.annotations.headers.Header;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@Validated @RestController @RequestMapping("/api/v1") @RequiredArgsConstructor
@Tag(name="Friends") @SecurityRequirement(name="accessBearer")
public class FriendsController {
    private final FriendProcessor friends;
    private final DuelInvitationProcessor invitations;
    private final FriendMapper mapper;
    @GetMapping("/users/me/friend-code")
    @Operation(operationId="getUsersMeFriendCode", summary="Get my stable friend code", description="Only JWT sub. Existing accounts allocate a code lazily once; code is stable across reconnect/restart and never returned for another account.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=FriendCodeResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public FriendCodeResponse code(@AuthenticationPrincipal Jwt jwt) { return mapper.toResponse(friends.code(user(jwt))); }

    @GetMapping("/friends")
    @Operation(operationId="getFriends", summary="List accepted friends", description="Active accounts only. Ordered friendsSince DESC,relationshipId ASC. No status/sort parameter.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=FriendsPage.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public FriendsPage friends(@AuthenticationPrincipal Jwt jwt, @RequestParam(defaultValue="0") @Min(0) int page, @RequestParam(defaultValue="20") @Min(1) @Max(100) int size) { return mapper.toResponse(friends.friends(user(jwt),page,size)); }

    @GetMapping("/friends/{friendId}")
    @Operation(operationId="getFriendProfile", summary="Get a friend profile with basic statistics", description="Accepted friendship required. Field set identical regardless of viewer/subject Free/Pro. No entitlements, topicStats, ratingHistory, history, email, birth, friendCode, payment or answers. Sample rank identifiers are illustrative; use real catalog values from the backend.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=FriendProfileResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public FriendProfileResponse profile(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID friendId) { return mapper.toResponse(friends.profile(user(jwt),friendId)); }

    @DeleteMapping("/friends/{friendId}")
    @Operation(operationId="removeFriend", summary="Remove friendship", description="Either side. Missing/already removed is 204. Cancel only PENDING room invitations between the pair; never surrender an accepted battle or cancel the host room. Emits REMOVED only on actual change.")
    @ApiResponse(responseCode="204", description="Success/idempotent no-op. Empty response body.", content=@Content)
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID friendId) { friends.remove(user(jwt),friendId); }

    @PostMapping("/friend-requests")
    @Operation(operationId="sendFriendRequest", summary="Send a friend request by personal code", description="Confirmation required. Same requester/same pending pair returns 200 existing. Crossed request is not automatic acceptance. After terminal state a later new send uses a NEW relationship id; pair cooldown and code-attempt limit apply.")
    @ApiResponse(responseCode="201", description="New resource created.", content=@Content(schema=@Schema(implementation=RelationshipResponse.class)))
    @ApiResponse(responseCode="200", description="Existing idempotent result; no duplicate change event.", content=@Content(schema=@Schema(implementation=RelationshipResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_CODE_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="SELF_FRIEND_REQUEST_NOT_ALLOWED; FRIEND_ALREADY_EXISTS; FRIEND_REQUEST_ALREADY_RECEIVED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="429", description="RATE_LIMITED", headers=@Header(name="Retry-After", schema=@Schema(type="integer", format="int64", minimum="1")), content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public ResponseEntity<RelationshipResponse> send(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody SendFriendRequest request) { var r=friends.send(user(jwt),request.getFriendCode()); return ResponseEntity.status(r.created()?201:200).body(mapper.toResponse(r.value())); }

    @GetMapping("/friend-requests")
    @Operation(operationId="getFriendRequests", summary="List pending incoming or outgoing friend requests", description="Only PENDING for JWT sub. Default INCOMING. Ordered createdAt DESC,id ASC; no expiration/history query.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=FriendRequestsPage.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public FriendRequestsPage requests(@AuthenticationPrincipal Jwt jwt, @RequestParam(defaultValue="INCOMING") FriendRequestDirection direction, @RequestParam(defaultValue="0") @Min(0) int page, @RequestParam(defaultValue="20") @Min(1) @Max(100) int size) { return mapper.toResponse(friends.requests(user(jwt),direction,page,size)); }

    @GetMapping("/friend-requests/{id}")
    @Operation(operationId="getFriendRequest", summary="Restore a known relationship request", description="Either participant can read retained status, including ACCEPTED/REMOVED; unrelated users receive 404.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=RelationshipResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_REQUEST_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public RelationshipResponse request(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(friends.get(user(jwt),id)); }

    @DeleteMapping("/friend-requests/{id}")
    @Operation(operationId="cancelFriendRequest", summary="Cancel my outgoing pending friend request", description="Requester only, no body. Repeated CANCELLED/other non-accepted terminal state is 204. ACCEPTED cannot be cancelled as a request; use DELETE /friends/{friendId}.")
    @ApiResponse(responseCode="204", description="Success/idempotent no-op. Empty response body.", content=@Content)
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_REQUEST_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="FRIEND_REQUEST_NOT_PENDING", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { friends.cancel(user(jwt),id); }

    @PostMapping("/friend-requests/{id}/accept")
    @Operation(operationId="acceptFriendRequest", summary="Accept incoming friend request", description="Recipient only. No body. Repeated ACCEPTED returns same state/version; other terminal states conflict. Wrong-role 403 only after participant access check.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=RelationshipResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_REQUEST_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="FRIEND_REQUEST_NOT_PENDING", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public RelationshipResponse accept(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(friends.respond(user(jwt),id,FriendStatus.ACCEPTED)); }

    @PostMapping("/friend-requests/{id}/decline")
    @Operation(operationId="declineFriendRequest", summary="Decline incoming friend request", description="Recipient only, no body. Repeated DECLINED is idempotent; other terminal states conflict.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=RelationshipResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="FRIEND_REQUEST_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="FRIEND_REQUEST_NOT_PENDING", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public RelationshipResponse decline(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(friends.respond(user(jwt),id,FriendStatus.DECLINED)); }

    @PostMapping("/duels/{duelId}/invitations")
    @Operation(operationId="inviteFriendToDuel", summary="Invite a friend to my existing waiting room", description="Host only; ACCEPTED friend required. Does not create another room or reserve the recipient. One pending target per room. Original deadline min(now+60s,room expiry). Persist sender/requestId receipts within room registry; same payload retry returns original current invitation even terminal; changed payload conflicts. Different requestId for same pending target aliases that invitation.")
    @ApiResponse(responseCode="201", description="New resource created.", content=@Content(schema=@Schema(implementation=DuelInvitationResponse.class)))
    @ApiResponse(responseCode="200", description="Existing idempotent result; no duplicate change event.", content=@Content(schema=@Schema(implementation=DuelInvitationResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_NOT_FOUND; FRIEND_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="DUEL_NOT_JOINABLE; DUEL_INVITATION_ALREADY_PENDING; IDEMPOTENCY_CONFLICT", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="410", description="DUEL_EXPIRED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="429", description="RATE_LIMITED", headers=@Header(name="Retry-After", schema=@Schema(type="integer", format="int64", minimum="1")), content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public ResponseEntity<DuelInvitationResponse> invite(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID duelId, @Valid @RequestBody SendDuelInvitationRequest request) { var r=invitations.send(user(jwt),duelId,request.getFriendId(),request.getRequestId());return ResponseEntity.status(r.created()?201:200).body(mapper.toResponse(r.value())); }

    @GetMapping("/duels/{duelId}/invitations")
    @Operation(operationId="getDuelOutgoingInvitations", summary="Restore my room pending invitation", description="Host only. Complete pending set for this room (at most one), not history. Terminal known room may return empty; room lost after restart is 404. Does not renew TTL.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=DuelInvitationsSnapshot.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public DuelInvitationsSnapshot outgoing(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID duelId) { return mapper.toResponse(invitations.outgoing(user(jwt),duelId)); }

    @GetMapping("/users/me/duel-invitations")
    @Operation(operationId="getUsersMeDuelInvitations", summary="List my pending incoming room invitations", description="Complete PENDING incoming set, ordered expiresAt,id. No body/query/pagination. Recipients can be offline/busy; receiving an invitation does not change activity. Restore after reconnect while original TTL remains.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=DuelInvitationsSnapshot.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public DuelInvitationsSnapshot incoming(@AuthenticationPrincipal Jwt jwt) { return mapper.toResponse(invitations.incoming(user(jwt))); }

    @GetMapping("/duel-invitations/{id}")
    @Operation(operationId="getDuelInvitation", summary="Restore known room invitation", description="Host or recipient only, including terminal state; lazy expiry/reconciliation, never TTL renewal. No room code returned. Backend restart loses this in-memory resource.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=DuelInvitationResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_INVITATION_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public DuelInvitationResponse invitation(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(invitations.get(user(jwt),id)); }

    @DeleteMapping("/duel-invitations/{id}")
    @Operation(operationId="withdrawDuelInvitation", summary="Withdraw my targeted room invitation", description="Host only, no body. 204 for PENDING->CANCELLED/SENDER_CANCELLED or other non-accepted terminal no-op. Does not cancel room. ACCEPTED conflicts and is never undone.")
    @ApiResponse(responseCode="204", description="Success/idempotent no-op. Empty response body.", content=@Content)
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_INVITATION_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="MATCH_ALREADY_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void withdraw(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { invitations.withdraw(user(jwt),id); }

    @PostMapping("/duel-invitations/{id}/accept")
    @Operation(operationId="acceptDuelInvitation", summary="Accept invitation and join its existing room", description="Recipient only, no body. Recheck friendship/activity/content/room atomically; exactly one guest/battle. Repeated ACCEPTED returns same invitation/battleId. Both still require Ready. Busy/content error leaves valid invitation pending; terminal state discovered during validation is committed before error response.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=DuelInvitationResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_INVITATION_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="DUEL_INVITATION_NOT_PENDING; ACTIVITY_CONFLICT; CONTENT_UNAVAILABLE", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="410", description="DUEL_INVITATION_EXPIRED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public DuelInvitationResponse acceptInvitation(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(invitations.accept(user(jwt),id)); }

    @PostMapping("/duel-invitations/{id}/decline")
    @Operation(operationId="declineDuelInvitation", summary="Decline incoming room invitation", description="Recipient only, no body. Repeated DECLINED and other non-accepted terminal states return their unchanged current state. ACCEPTED conflicts; restore own activity.")
    @ApiResponse(responseCode="200", description="Authoritative current response.", content=@Content(schema=@Schema(implementation=DuelInvitationResponse.class)))
    @ApiResponse(responseCode="400", description="VALIDATION_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="401", description="UNAUTHORIZED", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500", description="INTERNAL_ERROR", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="403", description="FORBIDDEN", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404", description="DUEL_INVITATION_NOT_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409", description="MATCH_ALREADY_FOUND", content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public DuelInvitationResponse declineInvitation(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(invitations.decline(user(jwt),id)); }

    private UUID user(Jwt jwt){return UUID.fromString(jwt.getSubject());}
}
