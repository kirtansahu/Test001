global class gl_AgentWorkUtils {
	webService static void createAgentWork(String serviceChannelID, String workItemId) {
		System.debug(
			'g_AgentWorkUtils createAgentWork serviceChannelID = ' +
			serviceChannelID +
			'   workItemId = ' +
			workItemId
		);
		agentWork agentWork;
		try {
			agentWork = new agentWork();
			agentWork.UserId = UserInfo.getUserId();
			agentWork.WorkItemId = workItemId;

			if (serviceChannelID != null) {
				agentWork.ServiceChannelId = serviceChannelID;
			}

			// receiving agent may exceed their set capacity to accept the item
			agentWork.ShouldSkipCapacityCheck = true;
		} catch (DmlException e) {
			System.debug('createAgentWork exception has occurred: ' + e.getMessage() + ' wrong parameters');
		}

		// get Presence status list
		Integer count = 1;

		while (count < 1) {
			try {
				insert agentWork;
				// exit the loop
				count = 0;
			} catch (DmlException e) {
				System.debug(
					'createAgentWork exception has occurred: ' +
					e.getMessage() +
					' try with next Presence status'
				);
				count--;
			}
		}
	}
}