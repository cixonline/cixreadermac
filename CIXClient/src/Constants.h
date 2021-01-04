//
//  Constants.h
//  CIXClient
//
//  Created by Steve Palmer on 27/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#ifndef CIXClient_Constants_h
#define CIXClient_Constants_h

// Notification constants
#define MADirectoryRefreshStarted           @"CC_Notify_DirectoryRefreshStarted"
#define MADirectoryRefreshCompleted         @"CC_Notify_DirectoryRefreshCompleted"
#define MADirectoryChanged                  @"CC_Notify_DirectoryChanged"

#define MAUserAuthenticationCompleted       @"CC_Notify_UserAuthenticationCompleted"
#define MAUserProfileChanged                @"CC_Notify_UserProfileChanged"
#define MAUserMugshotChanged                @"CC_Notify_UserMugshotChanged"

#define MAOnlineUsersRefreshed              @"CC_Notify_OnlineUsersRefreshed"
#define MAInterestingThreadsRefreshed       @"CC_Notify_InterestingThreadsRefreshed"

#define MAForumChanged                      @"CC_Notify_ForumChanged"
#define MAForumJoined                       @"CC_Notify_ForumJoined"
#define MAForumResigned                     @"CC_Notify_ForumResigned"
#define MAForumRequestedAdmission           @"CC_Notify_ForumRequestedAdmission"
#define MAForumLatestDate                   @"CC_Notify_ForumLatestDate"

#define MAFolderChanged                     @"CC_Notify_FolderChanged"
#define MAFolderAdded                       @"CC_Notify_FolderAdded"
#define MAFolderDeleted                     @"CC_Notify_FolderDeleted"
#define MAFolderUpdated                     @"CC_Notify_FolderUpdated"
#define MAFolderRefreshed                   @"CC_Notify_FolderRefreshed"
#define MAFolderRefreshStarted              @"CC_Notify_FolderRefreshedStarted"
#define MAFolderFixed                       @"CC_Notify_FolderFixed"

#define MAModeratorsUpdated                 @"CC_Notify_ModeratorsUpdated"
#define MAParticipantsUpdated               @"CC_Notify_ParticipantsUpdated"

#define MAConversationDeleted               @"CC_Notify_ConversationDeleted"
#define MAConversationAdded                 @"CC_Notify_ConversationAdded"
#define MAConversationChanged               @"CC_Notify_ConversationChanged"

#define MAMessageChanged                    @"CC_Notify_MessageChanged"
#define MAMessageAdded                      @"CC_Notify_MessageAdded"
#define MAMessageDeleted                    @"CC_Notify_MessageDeleted"

#define MARuleAdded                         @"CC_Notify_RuleAdded"

/** Notifies that a CIX service synchronisation has started
 
 This notification is broadcast when a CIX service synchronisation has started.
 To enable synchronisation, call the startTask: method on the CIX class. The
 object value in the NSNotification will be set to nil.
 */
#define MACIXSynchronisationStarted         @"CC_Notify_SynchronisationStarted"

/** Notifies that a CIX service synchronisation has completed.
 
 This notification is broadcast when a CIX service synchronisation has completed.
 The object value in the NSNotification will be set to nil.
 */
#define MACIXSynchronisationCompleted       @"CC_Notify_SynchronisationCompleted"
#endif
