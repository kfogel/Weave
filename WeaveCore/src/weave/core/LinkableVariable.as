/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.core
{
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableVariable;
	
	/**
	 * LinkableVariable allows callbacks to be added that will be called when the value changes.
	 * A LinkableVariable has an optional type restriction on the values it holds.
	 * 
	 * @author adufilie
	 */
	public class LinkableVariable extends CallbackCollection implements ILinkableVariable
	{
		/**
		 * This constructor does not allow an initial value to be specified, because no other class has a pointer to this object until the
		 * constructor completes, which means the value cannot be retrieved during any callbacks that would run in the constructor.  This
		 * forces the developer to set default values outside the constructor of the LinkableVariable, which means the callbacks will run
		 * the first time the value is set.  This behavior is desirable because it allows the initial value to be handled by the same code
		 * that handles new values.
		 * @param sessionStateType The type of values accepted for this sessioned property.
		 * @param verifier A function that returns true or false to verify that a value is accepted as a session state or not.  The function signature should be  function(value:*):Boolean.
		 */
		public function LinkableVariable(sessionStateType:Class = null, verifier:Function = null)
		{
			_sessionStateType = sessionStateType;
			_verifier = verifier;
		}

		/**
		 * valueEquals
		 * This function is used in setSessionState() to determine if the value has changed or not.
		 * Classes that extend this class may override this function.
		 */
		protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			// if there is no restriction on the type, use ObjectUtil.compare()
			if (_sessionStateType == null)
				return ObjectUtil.compare(_sessionState, otherSessionState) == 0;
			return _sessionState == otherSessionState;
		}
		
		/**
		 * isUndefined
		 * @return true if the session state is considered undefined.
		 */
		public function isUndefined():Boolean
		{
			return !_sessionStateWasSet || _sessionState == null;
		}
		
		/**
		 * This function is used to prevent the session state from having unwanted values.
		 * Function signature should be  function(value:*):Boolean
		 */		
		protected var _verifier:Function = null;

		protected var _sessionStateType:Class = null;
		public function getSessionStateType():Class
		{
			return _sessionStateType;
		}

		protected var _sessionState:* = null;
		public function getSessionState():Object
		{
			return _sessionState;
		}

		/**
		 * _sessionStateWasSet
		 * This is true if the session state has been set at least once.
		 */
		protected var _sessionStateWasSet:Boolean = false;
		
		/**
		 * Unless callbacks have been delayed with delayCallbacks(), this function will update _value and run callbacks.
		 * If this is not the first time setSessionState() is called and the new value equals the current value, this function has no effect.
		 * @param value The new value.  If the value given is of the wrong type, the value will be set to null.
		 */
		public function setSessionState(value:Object):void
		{
			if (_locked)
				return;

			// if the value is not the appropriate type, cast it now
			if (_sessionStateType != null)
				value = value as _sessionStateType;
			
			// stop if verifier says it's not an accepted value
			if (_verifier != null && !_verifier(value))
				return;
			
			// stop if the value did not change
			if (_sessionStateWasSet && sessionStateEquals(value))
				return;
			
			_sessionStateWasSet = true;

			_sessionState = value;

			triggerCallbacks();
		}

		/**
		 * lock
		 * Call this function when you do not want to allow any more changes to the value of this sessioned property.
		 */
		public function lock():void
		{
			_locked = true;
		}
		
		/**
		 * locked
		 * This is set to true when lock() is called.
		 * Subsequent calls to setSessionState() will have no effect.
		 */
		protected var _locked:Boolean = false;
		public function get locked():Boolean
		{
			return _locked;
		}

		override public function dispose():void
		{
			super.dispose();
			setSessionState(null);
		}
	}
}
