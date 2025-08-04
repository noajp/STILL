# RPC Functions Refactoring Plan

## 📋 Current State Analysis

The STILL app currently has **36 RPC functions** in the Supabase database. Many of these functions have overlapping functionality, complex logic, or could benefit from consolidation and optimization.

## 🎯 Refactoring Categories

### 1. **Duplicated Cleanup Functions** 🔄
**Current Functions:**
```sql
cleanup_old_rate_limits()     -- Deletes records older than 2 hours
cleanup_rate_limits()         -- Deletes records older than 24 hours
cleanup_expired_data()        -- Generic cleanup with policies
```

**Issues:**
- Same logic duplicated across multiple functions
- Different retention periods hardcoded
- No unified cleanup strategy

**Proposed Solution:**
```sql
-- Unified cleanup function with configurable retention
cleanup_data_by_retention(
    table_name text,
    retention_hours integer,
    date_column text DEFAULT 'created_at'
)
```

**Benefits:**
- Single source of truth for cleanup logic
- Configurable retention periods
- Easier maintenance and testing

---

### 2. **Counter Management Duplication** 📊
**Current Functions:**
```sql
increment_like_count(post_id)      -- Likes +1 with rate limiting
decrement_like_count(post_id)      -- Likes -1 with rate limiting
increment_comment_count()          -- Comments +1 (trigger function)
decrement_comment_count()          -- Comments -1 (trigger function)
```

**Issues:**
- Similar logic scattered across 4 functions
- Inconsistent rate limiting application
- Repeated counter update patterns

**Proposed Solution:**
```sql
-- Unified counter management
update_post_counter(
    post_id uuid,
    counter_type text,           -- 'like', 'comment', 'share', etc.
    increment_value integer,     -- +1, -1, or any value
    rate_limit_config jsonb     -- Optional rate limiting settings
)
```

**Benefits:**
- Consistent counter logic
- Easy to add new counter types
- Centralized rate limiting

---

### 3. **Complex Conversation Management** 💬
**Current Functions:**
```sql
get_or_create_direct_conversation()  -- 200+ lines, very complex
get_user_conversations()            -- Direct messages only
get_user_group_conversations()      -- Group chats only
```

**Issues:**
- `get_or_create_direct_conversation` is over 200 lines long
- Difficult to understand and maintain
- Similar query patterns duplicated

**Proposed Solution:**
```sql
-- Break down into smaller, focused functions
find_existing_conversation(user1_id uuid, user2_id uuid)
create_new_conversation(participants uuid[], is_group boolean)
get_conversations_with_metadata(user_id uuid, conversation_type text)
reset_conversation_visibility(conversation_id uuid, user_ids uuid[])
```

**Benefits:**
- Each function has single responsibility
- Easier to test and debug
- Reusable components

---

### 4. **Scattered Security Functions** 🔐
**Current Functions:**
```sql
log_security_event()          -- Security audit logging
anonymize_user_data()         -- Data anonymization
export_user_data()            -- GDPR data export
mask_sensitive_email()        -- Email privacy masking
configure_audit_settings()    -- Audit configuration
```

**Issues:**
- Security logic spread across multiple functions
- Inconsistent logging patterns
- Hard to maintain security standards

**Proposed Solution:**
```sql
-- Unified security audit system
audit_user_action(
    action_type text,
    resource_type text,
    resource_id text,
    metadata jsonb
)

-- Privacy control system
apply_privacy_rules(
    requesting_user_id uuid,
    data_owner_id uuid,
    data_type text,
    raw_data jsonb
)
```

**Benefits:**
- Centralized security logging
- Consistent privacy rule application
- Easier compliance management

---

### 5. **Insufficient Validation Functions** ✅
**Current Functions:**
```sql
validate_uuid_input(input_text)    -- UUID format validation
sanitize_text_input(input_text)    -- Basic text sanitization
```

**Issues:**
- Limited validation coverage
- No comprehensive input sanitization
- Missing common validation patterns

**Proposed Solution:**
```sql
-- Comprehensive validation suite
validate_input(
    input_value text,
    validation_type text,      -- 'uuid', 'email', 'username', etc.
    additional_rules jsonb     -- Custom validation rules
)

sanitize_user_content(
    content text,
    content_type text,         -- 'comment', 'caption', 'bio', etc.
    max_length integer
)
```

**Benefits:**
- Consistent validation across the app
- Easy to add new validation types
- Better security posture

---

## 🚀 Implementation Priority

### **Phase 1: High Priority (Immediate Impact)**
1. **Cleanup Functions Consolidation**
   - **Effort:** Low (2-3 hours)
   - **Impact:** High (easier maintenance)
   - **Risk:** Very Low

2. **Counter Functions Unification**
   - **Effort:** Medium (4-6 hours)
   - **Impact:** High (bug reduction, consistency)
   - **Risk:** Low (well-tested logic)

### **Phase 2: Medium Priority (Quality Improvement)**
3. **Conversation Management Refactoring**
   - **Effort:** High (8-12 hours)
   - **Impact:** Very High (maintainability)
   - **Risk:** Medium (complex logic changes)

4. **Validation Functions Enhancement**
   - **Effort:** Medium (4-6 hours)
   - **Impact:** High (security improvement)
   - **Risk:** Low (additive changes)

### **Phase 3: Low Priority (Future Enhancement)**
5. **Security Functions Reorganization**
   - **Effort:** High (8-10 hours)
   - **Impact:** Medium (already working well)
   - **Risk:** Medium (security-critical changes)

---

## 📈 Expected Benefits

### **Code Quality**
- **Reduced Duplication:** From 36 functions to ~25 focused functions
- **Improved Readability:** Shorter, single-purpose functions
- **Better Testing:** Smaller units easier to test

### **Maintenance**
- **Easier Updates:** Change logic in one place
- **Faster Debugging:** Clear function responsibilities
- **Reduced Bugs:** Less duplicate code to maintain

### **Performance**
- **Query Optimization:** Consolidated similar queries
- **Reduced Database Load:** More efficient function calls
- **Better Caching:** Smaller, focused functions cache better

### **Security**
- **Consistent Validation:** All inputs validated the same way
- **Centralized Security:** Security rules in one place
- **Better Auditing:** Unified logging approach

---

## 🧪 Testing Strategy

### **Before Refactoring**
1. **Document Current Behavior**
   - Create test cases for all existing functions
   - Record expected inputs/outputs
   - Note any edge cases or quirks

2. **Backup Strategy**
   - Create migration rollback scripts
   - Test rollback procedures
   - Keep old functions temporarily for comparison

### **During Refactoring**
1. **Incremental Changes**
   - Refactor one category at a time
   - Test each change thoroughly
   - Keep old and new functions side by side initially

2. **Validation Testing**
   - Compare outputs between old and new functions
   - Performance benchmarking
   - Load testing for critical functions

### **After Refactoring**
1. **Cleanup**
   - Remove old functions after validation period
   - Update documentation
   - Train team on new function structure

---

## 📝 Migration Notes

### **Database Migrations**
- Each refactoring phase should be a separate migration
- Include rollback procedures
- Test migrations on development environment first

### **Application Code Updates**
- Update Swift code to use new function signatures
- Replace direct SQL calls with new RPC functions
- Update error handling for new function behaviors

### **Monitoring**
- Add logging to track function usage
- Monitor performance metrics
- Set up alerts for function failures

---

## 🎯 Success Metrics

### **Quantitative Goals**
- **Reduce function count:** From 36 to ~25 functions
- **Reduce average function length:** Target <50 lines per function
- **Improve test coverage:** 90%+ coverage for all RPC functions
- **Performance improvement:** <10ms average response time

### **Qualitative Goals**
- **Better maintainability:** Easier for new developers to understand
- **Improved reliability:** Fewer bugs in production
- **Enhanced security:** Consistent validation and auditing
- **Better documentation:** Clear purpose for each function

---

## 🔧 Implementation Checklist

### **Pre-Implementation**
- [ ] Review current function usage in Swift code
- [ ] Create comprehensive test suite
- [ ] Set up monitoring and alerting
- [ ] Prepare rollback procedures

### **Phase 1: Cleanup & Counters**
- [ ] Implement unified cleanup function
- [ ] Migrate existing cleanup calls
- [ ] Implement unified counter function
- [ ] Update trigger functions
- [ ] Test thoroughly

### **Phase 2: Conversations & Validation**
- [ ] Break down complex conversation function
- [ ] Implement new conversation functions
- [ ] Enhance validation functions
- [ ] Update application calls

### **Phase 3: Security & Final Cleanup**
- [ ] Reorganize security functions
- [ ] Remove deprecated functions
- [ ] Update documentation
- [ ] Performance optimization

---

*Last Updated: January 4, 2025*
*Project: STILL iOS App - Supabase RPC Functions*